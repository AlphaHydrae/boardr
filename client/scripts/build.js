const chalk = require('chalk');
const dotenv = require('dotenv');
const { readFile, writeFile } = require('fs-extra');
const { template } = require('lodash');
const { join: joinPath, relative: relativePath, resolve: resolvePath } = require('path');

require('dotenv').config();

const root = resolvePath(joinPath(__dirname, '..'));
const indexPath = process.env.BOARDR_INDEX || joinPath(root, 'index.html');
const indexTemplatePath = joinPath(root, 'index.html.tpl');

Promise.resolve().then(build).catch(err => {
  console.error(chalk.red(err.stack));
  process.exit(1);
});

async function build() {

  const indexTemplateContents = await readFile(indexTemplatePath, 'utf8');
  const indexTemplate = template(indexTemplateContents);

  const indexContents = indexTemplate({
    apiUrl: JSON.stringify(process.env.BOARDR_API_URL || 'http://localhost:4000/api'),
    bundlePath: JSON.stringify(process.env.BOARDR_BUNDLE || '/elm.js')
  });

  await writeFile(indexPath, indexContents, 'utf8');
  console.log(`${chalk.yellow(relativePath(root, indexTemplatePath))} -> ${chalk.green(relativePath(root, indexPath))}`);
}
