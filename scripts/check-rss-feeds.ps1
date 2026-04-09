$feeds = @(
    @{name='cadzxw.com'; url='https://www.cadzxw.com/feed'},
    @{name='iplaysoft.com'; url='https://www.iplaysoft.com/feed'},
    @{name='xiaozhongjishu.com'; url='https://www.xiaozhongjishu.com/feed'},
    @{name='cdstm.cn'; url='https://www.cdstm.cn/rss'},
    @{name='std.samr.gov.cn'; url='https://std.samr.gov.cn/rss'},
    @{name='openstd.samr.gov.cn'; url='https://openstd.samr.gov.cn/rss'},
    @{name='gongbiaoku.com'; url='https://www.gongbiaoku.com/feed'},
    @{name='jianbiaoku.com'; url='http://www.jianbiaoku.com/feed'},
    @{name='softhome.cc'; url='https://www.softhome.cc/rss'},
    @{name='civilcn.com'; url='http://www.civilcn.com/rss'},
    @{name='fmhy.net'; url='https://fmhy.net/rss.xml'},
    @{name='zhihu.com-zhida'; url='https://www.zhihu.com/rss'},
    @{name='csdn.net'; url='https://www.csdn.net/article/rss'},
    @{name='36kr.com'; url='https://36kr.com/feed'},
    @{name='tmtpost.com'; url='https://tmtpost.com/rss'},
    @{name='toutiao.com'; url='https://www.toutiao.com/feed'},
    @{name='nature.com'; url='https://www.nature.com/latest-research.rss'},
    @{name='science.org'; url='https://www.sciencemag.org/rss/current.xml'},
    @{name='sina.com.cn'; url='https://rss.sina.com.cn/news/china/focus.xml'},
    @{name='bilibili-index'; url='https://www.bilibili.com/index/dingbang.json'},
    @{name='cnblogs'; url='https://www.cnblogs.com/rss'},
    @{name='segmentfault'; url='https://segmentfault.com/blog/recent/feed'},
    @{name='lizhi.io'; url='https://www.lizhi.io/feed'},
    @{name='deepseek'; url='https://chat.deepseek.com/rss'},
    @{name='platform.deepseek'; url='https://platform.deepseek.com/usage/rss'},
    @{name='npmjs'; url='https://registry.npmjs.org/-/rss'},
    @{name='github-csdn'; url='https://blog.csdn.net/weixin_/rss'},
    @{name='zhihu-zhida'; url='https://www.zhihu.com/people/tian-cai-jin-dong/posts'}
)

foreach($f in $feeds) {
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
