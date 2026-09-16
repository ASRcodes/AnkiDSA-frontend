import test from 'node:test';
import assert from 'node:assert/strict';
import {canonicalProblem,serverUrl,cleanProblem} from '../extension/core.js';
test('canonicalizes problem tabs without query variants',()=>{
 assert.equal(canonicalProblem('https://leetcode.com/problems/two-sum/description/?env=x'),'https://leetcode.com/problems/two-sum/');
});
test('rejects foreign pages and credential-bearing servers',()=>{
 for(const url of ['https://leetcode.com.evil.test/problems/x/','javascript:alert(1)','https://user@leetcode.com/problems/x/']) assert.throws(()=>canonicalProblem(url));
 for(const url of ['http://example.com','https://user:pass@example.com','https://example.com/path']) assert.throws(()=>serverUrl(url));
 assert.equal(serverUrl('http://localhost:8081/'),'http://localhost:8081');
});
test('missing difficulty cannot be silently stored as Medium',()=>{
 assert.throws(()=>cleanProblem({leetcodeUrl:'https://leetcode.com/problems/two-sum/',title:'Two Sum'}));
});
