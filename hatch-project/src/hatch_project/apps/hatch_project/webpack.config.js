const { NxAppWebpackPlugin } = require('@nx/webpack/app-plugin');
const { NxReactWebpackPlugin } = require('@nx/react/webpack-plugin');
const { NxWebpackPlugin } = require('@nx/webpack');
const path = require('path');

// Get the absolute path to the project root
const projectRoot = path.resolve(__dirname, '../../../../..');

module.exports = {
  output: {
    path: __dirname + '/dist',
  },
  devServer: {
    port: 4200,
    historyApiFallback: {
      index: '/index.html',
      disableDotRule: true,
      htmlAcceptHeaders: ['text/html', 'application/xhtml+xml'],
    },
  },
  plugins: [
    new NxAppWebpackPlugin({
      tsConfig: './tsconfig.app.json',
      compiler: 'babel',
      main: './src/main.tsx',
      index: './src/index.html',
      baseHref: '/',
      assets: ['./src/favicon.ico', './src/assets'],
      styles: ['./src/styles.css'],
      outputHashing: process.env['NODE_ENV'] === 'production' ? 'all' : 'none',
      optimization: process.env['NODE_ENV'] === 'production',
    }),
    new NxReactWebpackPlugin({
      // Uncomment this line if you don't want to use SVGR
      // See: https://react-svgr.com/
      // svgr: false
    }),
    new NxWebpackPlugin({
      assets: [
        {
          glob: 'apps/hatch_project/src/favicon.ico',
          input: projectRoot,  // Use absolute path to project root
          output: '.'
        }
      ],
      tsConfig: 'hatch-project/src/hatch_project/apps/hatch_project/tsconfig.app.json',
      compiler: 'babel',
      main: 'hatch-project/src/hatch_project/apps/hatch_project/src/main.tsx',
      index: 'hatch-project/src/hatch_project/apps/hatch_project/src/index.html',
      baseHref: '/',
      outputPath: 'dist/apps/hatch_project',
      target: 'web'
    })
  ],
};
