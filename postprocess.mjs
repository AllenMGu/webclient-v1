import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'

const [buildDirectory, sourcePage, noticeFile, licenseFile] = process.argv.slice(2)
if (!buildDirectory || !sourcePage || !noticeFile || !licenseFile) {
  throw new Error('usage: node postprocess.mjs <build-dir> <source-page> <notice> <license>')
}

const indexFile = path.join(buildDirectory, 'index.html')
let index = fs.readFileSync(indexFile, 'utf8')

const configAnchor = '<script src="ogvjs-1.8.6/ogv.js"></script>'
const configScript = '<script src="/webclient-config/index.js"></script>'
const configScriptCount = index.split(configScript).length - 1
if (configScriptCount > 1) {
  throw new Error(`expected at most one API configuration script, found ${configScriptCount}`)
}
if (index.split(configAnchor).length !== 2) {
  throw new Error('expected exactly one OGV script anchor')
}
if (configScriptCount === 0) {
  index = index.replace(configAnchor, configScript + '\n  ' + configAnchor)
}

const sourceStyle = `
  <style>
    .agpl-source-link {
      position: fixed;
      right: 12px;
      bottom: 10px;
      z-index: 2147483647;
      padding: 5px 8px;
      border-radius: 4px;
      background: rgba(255, 255, 255, 0.92);
      color: #303133;
      font: 12px/1.2 sans-serif;
      text-decoration: none;
      box-shadow: 0 1px 4px rgba(0, 0, 0, 0.24);
    }
  </style>`
const sourceStyleCount = (index.match(/\.agpl-source-link\s*\{/g) || []).length
if (sourceStyleCount > 1) {
  throw new Error(`expected at most one source-link style, found ${sourceStyleCount}`)
}
if (sourceStyleCount === 0) {
  index = index.replace('</head>', sourceStyle + '\n</head>')
}
const sourceLink = '<a class="agpl-source-link" href="SOURCE.html">Source · AGPL-3.0</a>'
const sourceLinkCount = index.split(sourceLink).length - 1
if (sourceLinkCount > 1) {
  throw new Error(`expected at most one source link, found ${sourceLinkCount}`)
}
if (sourceLinkCount === 0) {
  index = index.replace('<body>', '<body>\n  ' + sourceLink)
}

fs.copyFileSync(sourcePage, path.join(buildDirectory, 'SOURCE.html'))
fs.copyFileSync(noticeFile, path.join(buildDirectory, 'NOTICE'))
fs.copyFileSync(licenseFile, path.join(buildDirectory, 'AGPL-3.0.txt'))

// Flutter 3.7 generates a random service-worker version on every build. Build
// a canonical file list and derive the version from the actual resource tree
// so independent source builds are identical. Build metadata, the worker
// itself, and the separately downloadable corresponding source are not cached.
const resourceFiles = []
const collectResourceFiles = (directory, relativeDirectory = '') => {
  const entries = fs.readdirSync(directory, { withFileTypes: true })
    .sort((left, right) => left.name.localeCompare(right.name, 'en'))
  for (const entry of entries) {
    const relative = path.posix.join(relativeDirectory, entry.name)
    if (entry.name.startsWith('.')) continue
    if (relative === 'flutter_service_worker.js') continue
    if (relative === 'corresponding-source') continue
    const absolute = path.join(directory, entry.name)
    if (entry.isDirectory()) {
      collectResourceFiles(absolute, relative)
    } else if (entry.isFile()) {
      resourceFiles.push(relative)
    } else {
      throw new Error(`unsupported build entry: ${relative}`)
    }
  }
}
collectResourceFiles(buildDirectory)
resourceFiles.sort()

const versionHash = crypto.createHash('sha256')
for (const relative of resourceFiles) {
  if (relative === 'index.html') continue
  versionHash.update(relative)
  versionHash.update('\0')
  versionHash.update(fs.readFileSync(path.join(buildDirectory, relative)))
  versionHash.update('\0')
}
const serviceWorkerVersion = versionHash.digest('hex').slice(0, 16)
const versionPattern = /var serviceWorkerVersion = '[^']+';/g
const versionMatches = index.match(versionPattern)
if (!versionMatches || versionMatches.length !== 1) {
  throw new Error('expected exactly one generated service-worker version')
}
index = index.replace(
  versionPattern,
  `var serviceWorkerVersion = '${serviceWorkerVersion}';`
)
fs.writeFileSync(indexFile, index)

const md5 = (file) => crypto.createHash('md5').update(fs.readFileSync(file)).digest('hex')
const resources = {}
for (const relative of resourceFiles) {
  resources[relative] = md5(path.join(buildDirectory, relative))
}
resources['/'] = resources['index.html']

const serviceWorkerFile = path.join(buildDirectory, 'flutter_service_worker.js')
let serviceWorker = fs.readFileSync(serviceWorkerFile, 'utf8')
const resourcesPattern = /const RESOURCES = \{[\s\S]*?\n\};/g
const resourcesMatches = serviceWorker.match(resourcesPattern)
if (!resourcesMatches || resourcesMatches.length !== 1) {
  throw new Error('expected exactly one generated service-worker resource manifest')
}
serviceWorker = serviceWorker.replace(
  resourcesPattern,
  `const RESOURCES = ${JSON.stringify(resources, null, 2)};`
)
fs.writeFileSync(serviceWorkerFile, serviceWorker)
