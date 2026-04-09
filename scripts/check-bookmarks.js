const fs = require('fs');
const data = fs.readFileSync('C:\\Users\\Administrator\\AppData\\Local\\Microsoft\\Edge\\User Data\\Default\\Bookmarks');
const text = data.toString('utf8');
const parsed = JSON.parse(text);

function getAllURLs(node) {
    let urls = [];
    if (node.type === 'url') {
        urls.push({ name: node.name, url: node.url });
    }
    if (node.children) {
        for (const child of node.children) {
            urls = urls.concat(getAllURLs(child));
        }
    }
    return urls;
}

const allURLs = [];
for (const rootKey of Object.keys(parsed.roots)) {
    allURLs.push(...getAllURLs(parsed.roots[rootKey]));
}

// Filter out login pages, anchors, etc.
const filtered = allURLs.filter(u => 
    u.url && 
    u.url.startsWith('http') && 
    !u.url.match(/login|signin|account|#|javascript/i) &&
    !u.url.match(/qq\.com\/index/) &&
    !u.url.match(/pan\.baidu\.com/)
);

// Deduplicate by URL
const seen = new Set();
const unique = filtered.filter(u => {
    if (seen.has(u.url)) return false;
    seen.add(u.url);
    return true;
});

console.log('Total unique URLs:', unique.length);
unique.forEach(x => console.log(x.name + '|' + x.url));
