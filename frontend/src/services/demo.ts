import type {Issue} from '../types/domain';
const entries:[string,string,Issue['severity'],string,number,number,string,string][]=[
['Pothole near Ellis Bridge','POTHOLE','CRITICAL','PENDING_REVIEW',23.0218,72.5711,'Paldi','Roads & infrastructure'],
['Waterlogging on Ashram Road','WATER_LOGGING','HIGH','ASSIGNED',23.041,72.569,'Navrangpura','Drainage'],
['Streetlight outage · Riverfront','STREETLIGHT_FAILURE','MEDIUM','IN_PROGRESS',23.034,72.579,'Shahpur','Electrical'],
['Waste accumulation at market','GARBAGE_ACCUMULATION','HIGH','PENDING_REVIEW',23.025,72.587,'Jamalpur','Sanitation'],
['Damaged footpath · CG Road','FOOTPATH_DAMAGE','MEDIUM','VERIFIED',23.039,72.558,'Navrangpura','Roads & infrastructure'],
['Water pipeline leak','WATER_LEAKAGE','HIGH','IN_PROGRESS',23.015,72.558,'Paldi','Water supply'],
['Open manhole · Relief Road','OPEN_MANHOLE','CRITICAL','PENDING_REVIEW',23.031,72.591,'Kalupur','Drainage'],
['Traffic signal restored','SIGNAL_FAILURE','LOW','RESOLVED',23.045,72.584,'Shahibaug','Traffic'],
['Road surface damage','ROAD_DAMAGE','HIGH','DETECTED',23.051,72.562,'Naranpura','Roads & infrastructure'],
['Blocked stormwater drain','DRAINAGE_BLOCKAGE','HIGH','ASSIGNED',23.009,72.582,'Jamalpur','Drainage'],
['Streetlight repaired','STREETLIGHT_FAILURE','LOW','RESOLVED',23.018,72.597,'Khadia','Electrical'],
['Pothole on university road','POTHOLE','MEDIUM','VERIFIED',23.045,72.548,'Navrangpura','Roads & infrastructure']];
export const demoIssues:Issue[]=entries.map((e,i)=>({id:`demo-${i+1}`,issue_id:`CS-${String(1042+i).padStart(5,'0')}`,title:e[0],description:'Synthetic scenario for evaluating the city operations workflow. Location and observations require field verification before any action.',issue_type:e[1],severity:e[2],status:e[3],latitude:e[4],longitude:e[5],ward:e[6],assigned_department:e[7],priority_score:Math.max(38,96-i*4),confidence_score:97-i*3,address:`${e[6]}, Ahmedabad, Gujarat`,source:i%3===0?'AI detection':i%3===1?'Citizen report':'Field observation',created_at:new Date(Date.UTC(2026,8,8,8,i*5)).toISOString()}));
