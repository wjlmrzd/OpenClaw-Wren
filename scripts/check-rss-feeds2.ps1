$feeds2 = @(
    @{name='cadstudio.cz'; url='https://www.cadstudio.cz/feed'},
    @{name='tuostudy.com'; url='https://tuostudy.com/feed'},
    @{name='zhulong-forum'; url='https://www.zhulong.com/bbs/down/rss'},
    @{name='co188'; url='https://www.co188.com/rss'},
    @{name='xu5.cc'; url='https://www.xu5.cc/feed'},
    @{name='github-trending'; url='https://github.com/trending?feed=rss'},
    @{name='bilibili-user'; url='https://space.bilibili.com/612593877/video'},
    @{name='bilibili-rss'; url='https://rsshub.app/bilibili/user/video/612593877'},
    @{name='bilibili-rss2'; url='https://feed.bilibili.com/topic/rss'},
    @{name='npm-pkg'; url='https://www.npmjs.com/package/vite/feed'},
    @{name='npm-autolisp'; url='https://www.npmjs.com/package/autolisp/feed'},
    @{name='github-cadtotal'; url='https://github.com/liusong.1104.atom'},
    @{name='iplaysoft-soft'; url='https://www.iplaysoft.com/category/soft/feed'},
    @{name='wizhi-soft'; url='https://www.iplaysoft.com/feed'},
    @{name='zhihu-hot'; url='https://www.zhihu.com/hot/rss'},
    @{name='guokr'; url='https://www.guokr.com/rss'},
    @{name='jike'; url='https://jike.info/rss'},
    @{name='linux.do'; url='https://linux.do/rss'},
    @{name='linux.do-tag'; url='https://linux.do/tag/chatgpt/rss'},
    @{name='52pojie'; url='https://www.52pojie.cn/forum.php?mod=rss'},
    @{name='appinn'; url='https://www.appinn.com/feed'},
    @{name='mp.weixin'; url='https://mp.weixin.qq.com/rss'},
    @{name='mp.weixin2'; url='https://mp.weixin.qq.com/cgi/rss?type=atom'},
    @{name='jiumodiary'; url='https://www.jiumodiary.com/feed'},
    @{name='bilibili-rss3'; url='https://rsshub.app/bilibili/ranking/0/3'},
    @{name='bilibili-rss4'; url='https://rsshub.app/bilibili/ranking/0/1'},
    @{name='github-gpt5'; url='https://github.com/openai/gpt-5.atom'},
    @{name='ai-36kr'; url='https://36kr.com/feed'},
    @{name='v2ex'; url='https://www.v2ex.com/rss'},
    @{name='zhihu-daily'; url='https://www.zhihu.com/daily/feed'}
)

foreach($f in $feeds2) {
    $url = $f.url
    $nm = $f.name
    try {
        $r = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 6 -ErrorAction SilentlyContinue
        $code = $r.StatusCode
        Write-Host "$code $nm -> $url"
    } catch {
        Write-Host "XX $nm -> $($_.Exception.Message.Substring(0,[Math]::Min(40,$_.Exception.Message.Length)))"
    }
}
