import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: './',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    emptyOutDir: true,
    rollupOptions: {
      output: {
        manualChunks: {
          mermaid: ['mermaid'],
        },
      },
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  define: {
    'process.env': {},
  },
});
