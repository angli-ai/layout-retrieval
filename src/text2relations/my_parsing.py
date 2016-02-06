import os
import numpy as np
import scipy.io
import pickle
import collections
import json
from jsonrpc import ServerProxy, JsonRpc20, TransportTcpIp
from pprint import pprint

from nltk.tree import Tree

TEXT_FILE = 'written_text.txt'

class StanfordNLP:
    def __init__(self):
        self.server = ServerProxy(JsonRpc20(),
                                  TransportTcpIp(addr=("127.0.0.1", 8080)))
    
    def parse(self, text):
        return json.loads(self.server.parse(text))


def resolve_coref(sid, wid, visited_states, corefs):
    #print '[resolve_coref]', (sid, wid), 'visited_states: ', visited_states
    ret = [(sid, wid)]
    visited_states.add((sid, wid))
    for coref in corefs:
        if (coref[0][1], coref[0][2])==(sid, wid) and (coref[1][1], coref[1][2]) not in visited_states:
            ret.extend(resolve_coref(coref[1][1], coref[1][4]-1, visited_states, corefs))
        if (coref[1][1], coref[1][2])==(sid, wid) and (coref[0][1], coref[0][2]) not in visited_states:
            ret.extend(resolve_coref(coref[0][1], coref[0][4]-1, visited_states, corefs))
    return ret
    

def deterine_noun(loc, noun, dependencies):
    if noun == 'table':
        for d in dependencies:
            if 'table-%d'%(loc+1) == d[1] and ((d[0]=='nn' and d[2].startswith('side')) or
                                               (d[0]=='amod' and d[2].startswith('dinning'))): 
                noun = d[2].split('-')[0] + '-' + noun
    return noun

def process_result(result):
    # list of list for all sentences
    sentences = [[w[1]['Lemma'] for w in sent['words']] for sent in result['sentences']]

    noun_id = collections.defaultdict(int)
    coref_id = {}
    if result.has_key('coref'):
        corefs = result['coref'][0]
        # Resolve Coreference
        for coref in corefs:
            if (coref[0][1], coref[0][2]) not in coref_id.keys():
                # do DFS, return a set of coref occurences
                visited_states = set([])
                coref_nouns = resolve_coref(coref[0][1], coref[0][4]-1, visited_states, corefs)
                sid, wid = min(coref_nouns)
                hw = sentences[sid][wid]
                hw = deterine_noun(wid, hw, result['sentences'][sid]['dependencies'])
                for x, y in coref_nouns:
                    coref_id[(x, y)] = hw + '-%d' % noun_id[hw]
                noun_id[hw] = noun_id[hw] + 1

    relations = []
    nouns = []
    for sid, sent in enumerate(result['sentences']):
        #print 'SENTENCE: ', sent['text']
        #pprint(sent)

        # make a mapping between bed --> bed-1 by coreference
        noun_map = {}
        for i, w in enumerate(sent['words']):
            if w[1]['PartOfSpeech'].startswith('NN') or w[1]['PartOfSpeech'] == 'PRP':
                crid = coref_id.get((sid, i), -1)
                if crid != -1:
                    noun_map[w[0] + '-%d' % (i+1)] = crid
                elif w[1]['PartOfSpeech'].startswith(u'NN'):
                    noun = deterine_noun(i, w[1]['Lemma'], sent['dependencies'])
                    wid = noun_id[noun]
                    noun_map[w[0] + '-%d' % (i+1)] = noun + '-%d' % wid
                    noun_id[noun] += 1

        nouns.extend(noun_map.values())


        #print noun_map
        # extract prepositional dependencies
        for d in sent['dependencies']:
            if d[0].startswith('prep'):
                rel = d[0][5:]

                obj = noun_map[d[-1]]

                # find the subject of the relation
                anchor = d[1]
                sub = '##UNKNOWN##'
                for d2 in sent['dependencies']:
                    if d2[0] == 'nsubj' and d2[1] == anchor:
                        sub = noun_map[d2[-1]]

                if obj.startswith('side'):
                    # Special handle: left/right
                    # Find amod dependency (supposed to be left or right)
                    for d2 in sent['dependencies']:
                        if d2[0] == 'amod' and d2[1] == d[-1]:
                            rel = d2[-1].split('-')[0]

                    # Find the object of the relation
                    for d2 in sent['dependencies']:
                        if d2[1] == d[-1] and d2[0].startswith('prep'):
                            obj = noun_map[d2[-1]]

                if sub != '##UNKNOWN##':
                    relations.append((str(sub), str(obj), str(rel)))
    nouns = list(set(nouns))
    return relations, nouns

if __name__ == '__main__':
    nlp = StanfordNLP()

    lines = open(TEXT_FILE, 'r').readlines()
    for i in range(0, len(lines), 2):
        result = nlp.parse(lines[i+1].strip())
        relations, nouns = process_result(result)
        print lines[i].strip()
        print lines[i+1].strip()
        print relations
        print nouns

        if not os.path.exists('relations'):
            os.makedirs('relations')
        fn = 'relations/' + lines[i].strip()+'-relation.mat'
        A = np.zeros((1, len(relations)), dtype=np.object)
        for i, rel in enumerate(relations):
            A[0, i] = np.zeros((1, 3), dtype=np.object)
            A[0, i][:] = rel
        B = np.zeros((1, len(nouns)), dtype=np.object)
        B[:] = nouns
        scipy.io.savemat(fn, {'rel':A, 'nouns':B})
