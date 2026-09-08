import {Component} from 'react';
import type {ReactNode,ErrorInfo} from 'react';
import {Layers3,ArrowUpRight,LoaderCircle} from 'lucide-react';
import {Link} from 'react-router-dom';
import {useTranslation} from 'react-i18next';
import * as Dialog from '@radix-ui/react-dialog';
export function Logo(){return <Link to="/" className="brand"><span className="brand-mark"><Layers3 size={24}/></span><span>CivicSphere<small>URBAN INTELLIGENCE</small></span></Link>;}
export function Language(){const {i18n}=useTranslation();return <button className="language" onClick={()=>void i18n.changeLanguage(i18n.language==='en'?'hi':'en')} aria-label="Switch language">◎ <span>{i18n.language==='en'?'EN':'हिन्दी'}</span></button>;}
export function Badge({value}:{value:string}){return <span className={`badge ${value.toLowerCase()}`}>{value.replaceAll('_',' ').toLowerCase()}</span>;}
export function ArrowLink({to,children}:{to:string;children:ReactNode}){return <Link to={to} className="text-link">{children}<ArrowUpRight size={16}/></Link>;}
export function Loading(){const {t}=useTranslation();return <div className="state" role="status"><LoaderCircle className="spin"/><p>{t('loading')}</p></div>;}
export function ErrorState({message,retry}:{message:string;retry?:()=>void}){const {t}=useTranslation();return <div className="state" role="alert"><p>{message}</p>{retry&&<button onClick={retry}>{t('retry')}</button>}</div>;}
export class Boundary extends Component<{children:ReactNode},{failed:boolean}>{state={failed:false};static getDerivedStateFromError(){return {failed:true};}componentDidCatch(error:Error,info:ErrorInfo){console.error('CIVIC_UI_ERROR',{message:error.message,stack:info.componentStack});}render(){return this.state.failed?<div className="state" role="alert">This view could not load. <button onClick={()=>window.location.reload()}>Reload</button></div>:this.props.children;}}
export function Modal({open,onClose,title,children}:{open:boolean;onClose:()=>void;title:string;children:ReactNode}){return <Dialog.Root open={open} onOpenChange={v=>!v&&onClose()}><Dialog.Portal><Dialog.Overlay className="dialog-overlay"/><Dialog.Content className="dialog-content" aria-describedby={undefined}><Dialog.Title>{title}</Dialog.Title>{children}<Dialog.Close className="dialog-close" aria-label="Close">×</Dialog.Close></Dialog.Content></Dialog.Portal></Dialog.Root>;}
