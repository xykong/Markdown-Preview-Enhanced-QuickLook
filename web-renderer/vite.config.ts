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
    chunkSizeWarningLimit: 2000,
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
