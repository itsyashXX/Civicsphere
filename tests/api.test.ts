import {it,expect} from 'vitest';
import {handle} from '../api/_lib/handler';
import type {ResponseLike} from '../api/_lib/handler';
function response(){let code=0;let body:unknown;const res:ResponseLike={status(n){code=n;return res;},json(b){body=b;},setHeader(){}};return {res,get code(){return code;},get body(){return body;}};}
it('fails closed with missing configuration',async()=>{const r=response();await handle({method:'GET',url:'/api/issues',headers:{}},r.res,{});expect(r.code).toBe(503);expect(r.body).toMatchObject({success:false,error:{code:'NOT_CONFIGURED'}});});
it('rejects unauthenticated API access before database calls',async()=>{const r=response();await handle({method:'GET',url:'/api/issues',headers:{}},r.res,{SUPABASE_URL:'https://example.supabase.co',SUPABASE_PUBLISHABLE_KEY:'sb_publishable_example_example'});expect(r.code).toBe(401);});
