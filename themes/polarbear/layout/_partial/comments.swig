{% if theme.wangyiyun_gentie %}
    <section id="comments">
        <div id="cloud-tie-wrapper" class="cloud-tie-wrapper">
        </div>

        <script src="https://img1.cache.netease.com/f2e/tie/yun/sdk/loader.js">
        </script>

        <script>
            var identifier='http://zaf1ro.github.io/'+'{{ page.path }}';var cloudTieConfig={url:identifier,sourceId:identifier,productKey:"f1ca405ced434798a631e194759f0596",target:"cloud-tie-wrapper"};var yunManualLoad=!0;Tie.loader("aHR0cHM6Ly9hcGkuZ2VudGllLjE2My5jb20vcGMvbGl2ZXNjcmlwdC5odG1s",!0)
        </script>
    </section>
{% endif %}