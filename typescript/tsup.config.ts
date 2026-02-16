import { defineConfig } from 'tsup';

export default defineConfig({
  clean:true,
  dts:true,
  entry:['src/index.ts'],
  format:['cjs', 'esm', 'iife'],
  globalName:'httpstate',
  minify:true,
  outExtension:args => {
    let format:string = args.format;

    if(format === 'iife')
      format = 'global';

    return { js:'.' + format + '.js' };
  },
  sourcemap:true,
  target:'esnext'
});
