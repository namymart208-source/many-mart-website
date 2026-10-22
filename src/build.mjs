// Optional developer rebuild. Not needed to upload the prebuilt site folder.
import {build} from 'esbuild';
await build({entryPoints:['main.tsx'],outfile:'../site/app.js',bundle:true,minify:true,platform:'browser',format:'iife',target:'es2020',define:{'process.env.NODE_ENV':'"production"'}});
