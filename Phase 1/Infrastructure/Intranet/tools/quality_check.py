#!/usr/bin/env python3
"""Offline structural/compatibility checks for the static intranet."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit
import re, sys, xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
errors=[]; warnings=[]; metrics={}

class AuditParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links=[]; self.assets=[]; self.ids=set(); self.labels=set(); self.controls=[]
        self.images=[]; self.tables=[]; self._table=None; self.metas=[]; self.scripts=[]; self.styles=[]
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if 'id' in a: self.ids.add(a['id'])
        if tag=='a' and 'href' in a: self.links.append(a['href'])
        if tag=='img': self.images.append(a); self.assets.append(a.get('src',''))
        if tag=='script' and a.get('src'): self.scripts.append(a['src']); self.assets.append(a['src'])
        if tag=='link' and a.get('href'): self.styles.append(a['href']); self.assets.append(a['href'])
        if tag=='label' and a.get('for'): self.labels.add(a['for'])
        if tag in ('input','select','textarea'):
            if not (tag=='input' and a.get('type','text') in ('hidden','submit','button','reset')):
                self.controls.append((tag,a.get('id',''),a))
        if tag=='table': self._table={'caption':False,'th':False}; self.tables.append(self._table)
        if tag=='caption' and self._table is not None: self._table['caption']=True
        if tag=='th' and self._table is not None: self._table['th']=True
        if tag=='meta': self.metas.append(a)
    def handle_endtag(self, tag):
        if tag=='table': self._table=None

def clean_ref(ref):
    return urlsplit(ref).path

htmls=sorted(ROOT.glob('*.html'))
metrics['html_pages']=len(htmls)
for p in htmls:
    text=p.read_text(encoding='utf-8')
    parser=AuditParser()
    try: parser.feed(text)
    except Exception as e: errors.append(f'{p.name}: HTML parser error: {e}')
    if not text.lstrip().lower().startswith('<!doctype html>'): errors.append(f'{p.name}: missing standards doctype')
    if not any(m.get('http-equiv','').lower()=='x-ua-compatible' and m.get('content','').lower()=='ie=edge' for m in parser.metas): errors.append(f'{p.name}: missing IE=edge metadata')
    if 'main-content' not in parser.ids or not any(x=='#main-content' for x in parser.links): errors.append(f'{p.name}: skip target/link missing')
    for img in parser.images:
        if 'alt' not in img: errors.append(f'{p.name}: image missing alt: {img.get("src","")}')
    for tag,cid,attrs in parser.controls:
        if not cid: errors.append(f'{p.name}: {tag} control lacks id')
        elif cid not in parser.labels and attrs.get('readonly') is None:
            errors.append(f'{p.name}: control {cid} has no associated label')
    for idx,t in enumerate(parser.tables,1):
        if not t['caption']: errors.append(f'{p.name}: table {idx} lacks caption')
        if not t['th']: errors.append(f'{p.name}: table {idx} lacks headers')
    for ref in parser.assets:
        path=clean_ref(ref)
        if not path or ref.startswith(('http://','https://','//')): continue
        target=(p.parent/path).resolve()
        if ROOT not in target.parents and target!=ROOT: errors.append(f'{p.name}: escaping asset path {ref}')
        elif not target.exists(): errors.append(f'{p.name}: missing asset {ref}')
    for ref in parser.links:
        if ref.startswith(('#','mailto:','tel:','javascript:','http://','https://','//')): continue
        path=clean_ref(ref)
        target=(p.parent/path).resolve()
        if not target.exists(): errors.append(f'{p.name}: broken link {ref}')
        elif target.suffix.lower()=='.html':
            frag=urlsplit(ref).fragment
            if frag:
                q=AuditParser(); q.feed(target.read_text(encoding='utf-8'))
                if frag not in q.ids: errors.append(f'{p.name}: missing anchor {ref}')

# CSS local URL checks
for p in sorted((ROOT/'assets/css').glob('*.css')):
    text=p.read_text(encoding='utf-8')
    for ref in re.findall(r'url\(["\']?([^"\')]+)', text):
        if ref.startswith(('data:','http://','https://','//')): continue
        if not (p.parent/ref).resolve().exists(): errors.append(f'{p.relative_to(ROOT)}: missing CSS asset {ref}')

# JavaScript ES5 and safety checks
jsfiles=sorted((ROOT/'assets').glob('**/*.js'))
metrics['javascript_files']=len(jsfiles)
patterns={
    r'=>':'arrow function', r'`':'template literal', r'\b(?:let|const)\s+[A-Za-z_$]':'let/const declaration',
    r'\bclass\s+[A-Za-z_$]':'class declaration', r'\basync\s+function\b':'async function',
    r'\bawait\b':'await', r'\?\.':'optional chaining', r'\?\?':'nullish coalescing',
    r'\.\.\.\s*[A-Za-z_$]':'spread/rest', r'\bfetch\s*\(':'fetch', r'\bPromise\b':'Promise',
    r'\b(?:Map|Set)\s*\(':'Map/Set', r'\beval\s*\(':'eval', r'document\.write\s*\(':'document.write',
    r'\blocalStorage\b':'localStorage', r'\bActiveXObject\b':'ActiveX'
}
for p in jsfiles:
    text=p.read_text(encoding='utf-8')
    for pat,name in patterns.items():
        if re.search(pat,text): errors.append(f'{p.relative_to(ROOT)}: prohibited/modern construct: {name}')
for p in sorted((ROOT/'assets/data').glob('*.js')):
    text=p.read_text(encoding='utf-8')
    if 'window.GrandMachinato' not in text or '.Data' not in text: errors.append(f'{p.relative_to(ROOT)}: not attached to controlled namespace')

# Offline requirement: no external runtime URLs
runtime=list(htmls)+list((ROOT/'assets').glob('**/*'))
for p in runtime:
    if not p.is_file() or p.suffix.lower() in ('.png','.jpg','.jpeg','.gif','.ico'): continue
    text=p.read_text(encoding='utf-8',errors='ignore')
    if re.search(r'https?://',text): errors.append(f'{p.relative_to(ROOT)}: external runtime URL found')

# Secret-shaped assignments (ordinary guidance words are permitted)
secret_pat=re.compile(r'(?i)(?:api[_-]?key|password|secret|token)\s*[:=]\s*["\'][^"\']{4,}["\']')
for p in list(ROOT.glob('*.html'))+list((ROOT/'assets').glob('**/*.js')):
    if secret_pat.search(p.read_text(encoding='utf-8',errors='ignore')): errors.append(f'{p.relative_to(ROOT)}: secret-shaped literal found')

# XML configuration well-formedness
for rel in ['config/sample-enterprise-mode-site-list.xml','config/web.config','web.config']:
    p=ROOT/rel
    if not p.exists(): errors.append(f'missing required configuration: {rel}')
    else:
        try: ET.parse(p)
        except Exception as e: errors.append(f'{rel}: XML parse error: {e}')

# Required files/pages
required=['index.html','news.html','service-desk.html','system-status.html','applications.html','employee-directory.html','hr-resources.html','policies.html','forms-requests.html','infrastructure.html','knowledge-base.html','useful-links.html','contact-support.html','access-denied.html','not-found.html','search.html','README.md','docs/installation.md','docs/ie-mode-configuration.md','docs/compatibility-matrix.md','docs/ie-mode-testing.md','docs/security-notes.md','docs/future-aspnet-architecture.md','docs/migration-plan.md','docs/content-update-guide.md']
for rel in required:
    if not (ROOT/rel).exists(): errors.append(f'missing required deliverable: {rel}')

metrics['files']=sum(1 for p in ROOT.rglob('*') if p.is_file())
metrics['images']=sum(1 for p in (ROOT/'assets/images').rglob('*') if p.is_file())
print('Grand Machinato quality check')
for k,v in sorted(metrics.items()): print(f'{k}: {v}')
print(f'errors: {len(errors)}')
print(f'warnings: {len(warnings)}')
for x in errors: print('ERROR:',x)
for x in warnings: print('WARN:',x)
sys.exit(1 if errors else 0)
