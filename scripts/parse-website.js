const fs = require('fs');
const data = JSON.parse(fs.readFileSync('website-monitor-output.json', 'utf8'));
const changed = data.results.filter(x => x.changed && x.status === 'success');
console.log('=== 网站更新报告 (2026-04-03) ===\n');
changed.forEach(site => {
  console.log(`📌 ${site.name}`);
  console.log(`   URL: ${site.url}`);
  console.log(`   更新: ${site.new_links_count} 个新链接`);
  if (site.changes.length) site.changes.forEach(c => console.log(`   - ${c}`));
  console.log('');
});
console.log(`共 ${changed.length} 个网站有更新`);