import {createClient} from '@supabase/supabase-js';
import {z} from 'zod';
const parsed=z.object({url:z.url(),key:z.string().min(20)}).safeParse({url:import.meta.env.VITE_SUPABASE_URL,key:import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY});
export const supabase=parsed.success?createClient(parsed.data.url,parsed.data.key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
export function requireClient(){if(!supabase)throw new Error('The city workspace is not connected yet. Contact your administrator.');return supabase;}
