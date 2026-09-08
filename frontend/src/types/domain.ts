export const roles = ['SUPER_ADMIN','ADMIN','CITY_OFFICER','DEPARTMENT_MANAGER','GIS_ANALYST','FIELD_OFFICER','REVIEWER','DATA_MANAGER','REPORT_ANALYST','VIEWER','PUBLIC_USER'] as const;
export type Role = typeof roles[number];
export type Profile = {id:string; organization_id:string; department_id:string|null; role:Role; display_name:string; is_active:boolean};
export type Severity = 'CRITICAL'|'HIGH'|'MEDIUM'|'LOW'|'INFO';
export type Issue = {id:string;issue_id:string;title:string;description:string;status:string;severity:Severity;issue_type:string;priority_score:number;confidence_score:number;latitude:number;longitude:number;ward:string;address:string;source:string;created_at:string;assigned_department:string|null};
export const reviewRoles:Role[]=['SUPER_ADMIN','ADMIN','CITY_OFFICER','REVIEWER'];
export const adminRoles:Role[]=['SUPER_ADMIN','ADMIN'];
export function permitted(profile:Profile|null, allowed:Role[]){return !!profile?.is_active && allowed.includes(profile.role);}
export function priority(factors:number[]){if(factors.length!==7||factors.some(n=>!Number.isFinite(n)||n<0||n>100))throw new Error('Invalid priority inputs');return Math.round(factors.reduce((s,n,i)=>s+n*[.25,.15,.15,.2,.1,.05,.1][i],0));}
export function confidenceBand(score:number){if(!Number.isFinite(score)||score<0||score>100)throw new Error('Invalid confidence');return score>=90?'HIGH':score>=70?'MEDIUM':'LOW';}
