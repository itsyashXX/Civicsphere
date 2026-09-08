import {createContext,useContext,useEffect,useState} from 'react';
import type {ReactNode} from 'react';
import type {Session} from '@supabase/supabase-js';
import {supabase} from '../../services/client';
import type {Profile} from '../../types/domain';
const Context=createContext<{session:Session|null;profile:Profile|null;loading:boolean}>({session:null,profile:null,loading:true});
export function AuthProvider({children}:{children:ReactNode}){const [session,setSession]=useState<Session|null>(null);const [profile,setProfile]=useState<Profile|null>(null);const [loading,setLoading]=useState(true);useEffect(()=>{if(!supabase){setLoading(false);return;}let active=true;const client=supabase;const load=async(s:Session|null)=>{if(!active)return;setSession(s);setProfile(null);if(s){const {data}=await client.from('profiles').select('id,organization_id,department_id,role,display_name,is_active').eq('id',s.user.id).single();if(active)setProfile(data);}if(active)setLoading(false);};void client.auth.getSession().then(({data})=>load(data.session));const {data:{subscription}}=client.auth.onAuthStateChange((_e,s)=>{window.setTimeout(()=>void load(s),0);});return()=>{active=false;subscription.unsubscribe();};},[]);return <Context.Provider value={{session,profile,loading}}>{children}</Context.Provider>;}
export const useAuth=()=>useContext(Context);
