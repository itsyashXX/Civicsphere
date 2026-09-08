import {handle} from './_lib/handler.js';
import type {RequestLike,ResponseLike} from './_lib/handler.js';
export default async function handler(req:RequestLike,res:ResponseLike){return handle(req,res,process.env);}
