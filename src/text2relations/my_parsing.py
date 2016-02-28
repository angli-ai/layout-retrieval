import os
import numpy as np
import scipy.io
import pickle
import collections
import json
from jsonrpc import ServerProxy, JsonRpc20, TransportTcpIp
from pprint import pprint

from nltk.tree import Tree

TEXT_FILE = 'written_text-all.txt'
TEXT_FILE = 'sunrgbd_text.txt'
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
        #if (((coref[0][1], coref[0][2])==(sid, wid)) or (coref[0][2] == -1 and coref[0][1] == sid and coref[0][3] <= wid and coref[0][4] > wid)) and (coref[1][1], coref[1][4]-1) not in visited_states:
        if ((coref[0][1], coref[0][4]-1)==(sid, wid)) and (coref[1][1], coref[1][4]-1) not in visited_states:
            ret.extend(resolve_coref(coref[1][1], coref[1][4]-1, visited_states, corefs))
        #if ((coref[1][1], coref[1][2])==(sid, wid) or (coref[1][2] == -1 and coref[1][1] == sid and coref[1][3] <= wid and coref[1][4] > wid))and (coref[0][1], coref[0][4]-1) not in visited_states:
        if ((coref[1][1], coref[1][4]-1)==(sid, wid)) and (coref[0][1], coref[0][4]-1) not in visited_states:
            ret.extend(resolve_coref(coref[0][1], coref[0][4]-1, visited_states, corefs))
    return ret
    

def deterine_noun(loc, noun, dependencies):
    if noun == 'table':
        print(loc, noun, dependencies)
        for d in dependencies:
            if 'table-%d'%(loc+1) == d[1] and ((d[0]=='nn' and d[2].startswith('side')) or
                                               (d[0]=='nn' and d[2].startswith('dining'))): 
                noun = d[2].split('-')[0] + '-' + noun
    elif noun == 'stand':
        print(loc, noun, dependencies)
        for d in dependencies:
            if 'stand-%d'%(loc+1) == d[1] and ((d[0]=='nn' and d[2].startswith('night'))):
                noun = d[2].split('-')[0] + '-' + noun
    return noun

def process_result(result):
    # list of list for all sentences
    sentences = [[w[1]['Lemma'] for w in sent['words']] for sent in result['sentences']]

    noun_id = collections.defaultdict(int)
    coref_id = {}
    if result.has_key('coref'):
        for corefs in result['coref']:
            #corefs = result['coref'][0]
            print(corefs)
            # Resolve Coreference
            for coref in corefs:
                if (coref[0][1], coref[0][2]) not in coref_id.keys():
                    # do DFS, return a set of coref occurences
                    visited_states = set([])
                    coref_nouns = resolve_coref(coref[0][1], coref[0][4]-1, visited_states, corefs)
                    #print('coref_nous: ', coref_nouns)
                    sid, wid = min(coref_nouns)
                    #print(sentences[2])
                    hw = sentences[sid][wid]
                    hw = deterine_noun(wid, hw, result['sentences'][sid]['dependencies'])
                    new_coref_id = ''
                    for x, y in coref_nouns:
                        if (x, y) in coref_id:
                            new_coref_id = coref_id[(x, y)]
                    if new_coref_id == '':
                        new_coref_id = hw + '-%d' % noun_id[hw]
                        noun_id[hw] = noun_id[hw] + 1
                    for x, y in coref_nouns:
                        coref_id[(x, y)] = new_coref_id
                    #print('coref: ', coref, coref_nouns, hw)

    relations = []
    nouns = []

    relation_set = ['beside', 'near', 'above', 'on', 'behind', 'front', 'left', 'right', 'in_front_of', 'by']
    prep_relation_set = ['prep_' + x for x in relation_set]
    noun_cnt = {}
    for sid, sent in enumerate(result['sentences']):
        #print 'SENTENCE: ', sent['text']
        #pprint(sent)

        # make a mapping between bed --> bed-1 by coreference
        noun_map = {}
        prev_w = []

        NN_map = ['dining-table', 'side-table']
        NNS_map = [x + 's' for x in NN_map]
        for i, w in enumerate(sent['words']):
            if w[1]['PartOfSpeech'] == 'JJ':
                if w[1]['Lemma'] in NN_map:
                    w[1]['PartOfSpeech'] = 'NN'
                elif w[1]['Lemma'] in NNS_map:
                    w[1]['PartOfSpeech'] = 'NNS'

        for i, w in enumerate(sent['words']):
            if w[1]['PartOfSpeech'].startswith('NN') or w[1]['PartOfSpeech'] == 'PRP':
                crid = coref_id.get((sid, i), -1)
                if crid != -1:
                    noun_map[w[0] + '-%d' % (i+1)] = crid
                    noun_name = crid
                    # noun_cnt[crid] = '1'
                elif w[1]['PartOfSpeech'].startswith(u'NN'):
                    noun = deterine_noun(i, w[1]['Lemma'], sent['dependencies'])
                    wid = noun_id[noun]
                    noun_name = noun + '-%d' % wid
                    noun_map[w[0] + '-%d' % (i+1)] = noun_name
                    noun_id[noun] += 1

                if not noun_name in noun_cnt:
                    if w[1]['PartOfSpeech'].startswith('NNS'):
                        #print('(prev_w, w) =', prev_w, w)
                        # is plural
                        if prev_w[1]['PartOfSpeech'].startswith('CD'):
                            noun_cnt[noun_name] = prev_w[1]['NormalizedNamedEntityTag']
                        elif prev_w[1]['Lemma'] == 'many':
                            noun_cnt[noun_name] = 'many'
                        elif prev_w[1]['Lemma'] == 'some':
                            noun_cnt[noun_name] = 'some'
                        else:
                            print('unprocessed count:', prev_w[1]['Lemma'])
                    else:
                        noun_cnt[noun_name] = '1'
                    #print('(noun, cnt) = ', noun_name, noun_cnt[noun_name])
            prev_w = w


        nouns.extend(noun_map.values())

        #print noun_map
        # extract prepositional dependencies
        for d in sent['dependencies']:
            if d[0].startswith('prep') and d[0] in prep_relation_set:
                #print('prep dep: ', d)
                rel = d[0][5:]

                cnt = 0
                obj = d[-1]
                mapped_obj = ''
                obj_attrib = ''

                if d[0] == 'prep_by' and d[1].startswith('side') and d[2].startswith('side'):
                    rel = 'side-by-side'
                    obj = ''
                    mapped_obj = 'each-other'

                if obj.startswith('side'):
                    # Special handle: left/right
                    # Find amod dependency (supposed to be left or right)
                    for d2 in sent['dependencies']:
                        if d2[0] == 'amod' and d2[1] == d[-1]:
                            rel = d2[-1].split('-')[0]

                    # Find the object of the relation
                    for d2 in sent['dependencies']:
                        if d2[1] == d[-1] and d2[0] == 'prep_of':
                            obj = d2[-1]

                if obj.startswith('head'):
                    # check 'head of something'
                    for d2 in sent['dependencies']:
                        if d2[0] == 'prep_of' and d2[1].startswith('head'):
                            obj = d2[2]
                            obj_attrib = "head"
                            break

                # check 'prep each other'
                if obj.startswith('other'):
                    # find 'each'
                    # obj = 'not-each-other'
                    for d2 in sent['dependencies']:
                        if d2[0] == 'det' and d2[1].startswith('other') and d2[2].startswith('each'):
                            # found each other
                            mapped_obj = 'each-other'
                            break

                if mapped_obj == '':
                    mapped_obj = noun_map[obj]
                if obj_attrib != '':
                    mapped_obj = mapped_obj + ":" + obj_attrib

                # find the subject of the relation
                anchor = d[1]
                sub = '##UNKNOWN##'
                for d2 in sent['dependencies']:
                    if d2[0] == 'nsubj' and d2[1] == anchor:
                        if d2[2].startswith('that'):
                            # find rcmod, noun, anchor
                            for d2 in sent['dependencies']:
                                if d2[0] == 'rcmod' and d2[2] == anchor:
                                    sub = noun_map[d2[1]]
                                    cnt = noun_cnt[sub]
                                    break
                        else:
                            sub = noun_map[d2[-1]]
                            #print('sub: ', sub)
                            cnt = noun_cnt[sub]
                        break
                #print('sub: ', sub)

                if sub != '##UNKNOWN##':
                    relations.append((str(sub), str(mapped_obj), str(rel)))
                    print(cnt, sub, mapped_obj, rel)
    nouns = list(set(nouns))

    nouns_in_relations = [x[0] for x in relations] + [x[1] for x in relations]
    nouns = [x for x in nouns if x in nouns_in_relations]
    noun_cnt = { mykey: noun_cnt[mykey] for mykey in nouns }
    return relations, nouns, noun_cnt

if __name__ == '__main__':
    nlp = StanfordNLP()

    lines = open(TEXT_FILE, 'r').readlines()
    for i in range(0, len(lines), 2):
        #currentline = lines[i+1].strip().replace("side table", "side-table").replace("dining table", "dining-table")
        currentline = lines[i+1].strip()
        result = nlp.parse(currentline)
        relations, nouns, noun_cnt = process_result(result)
        print lines[i].strip()
        print lines[i+1].strip()
        #print currentline
        print relations
        print nouns

        if not os.path.exists('relations'):
            os.makedirs('relations')
        fn = 'relations/' + lines[i].strip()+'-relation.mat'
        A = np.zeros((1, len(relations)), dtype=np.object)
        for i, rel in enumerate(relations):
            A[0, i] = np.zeros((1, 3), dtype=np.object)
            A[0, i][:] = rel
        B = np.zeros((2, len(noun_cnt)), dtype=np.object)
        j = 0
        print(noun_cnt)
        for k in noun_cnt:
            B[0, j] = k
            B[1, j] = noun_cnt[k]
            j = j + 1
        scipy.io.savemat(fn, {'rel':A, 'nouns':B})
