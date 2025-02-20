const { NxAppWebpackPlugin } = require('@nx/webpack/app-plugin');
const { NxReactWebpackPlugin } = require('@nx/react/webpack-plugin');
const path = require('path');

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
      assets: [
        {
          glob: 'src/favicon.ico',  // Relative to the app directory
          input: __dirname,  // Current directory (where webpack.config.js is)
          output: '.'
        }
      ],
      tsConfig: './tsconfig.app.json',  // Relative path
      compiler: 'babel',
      main: './src/main.tsx',  // Relative path
      index: './src/index.html',  // Relative path
      baseHref: '/',
      outputPath: 'dist/apps/hatch_project',
      target: 'web'
    }),
    new NxReactWebpackPlugin({
      // Uncomment this line if you don't want to use SVGR
      // See: https://react-svgr.com/
      // svgr: false
    }),
  ]
};
