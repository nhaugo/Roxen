<use file='/template' />
<tmpl title='{{ title }}'{{#noform}} noform='noform'{{/noform}}>
  <topmenu base='/' selected='sites'/>
  <content>
    <cv-split>
      <subtablist>
        <st-tabs/>
        <st-page>
          <cf-title>{{ title }}</cf-title/>

          <if not='1' variable='form.initial'>
            {{^noform}}
              <input type='hidden' name='reload' value='1'>
            {{/noform}}

            <div class='flex-row space-around padded clear-float'>
              <div class='flex flex-shrink'>
                <!-- AJAX search form -->
                <form action=''>
                  <roxen-wizard-id-variable />
                  <input type='hidden' name='config' value='&form.config;'>
                  <if variable="form.unfolded">
                    <input type='hidden' name='unfolded' value='&form.unfolded;'>
                  </if>
                  <div class='control-group inline'>
                    <default variable='form.method' value='{{ method }}'>
                      <select name='method' id='list-type'
                        data-auto-submit='' data-add-variable='reload=1' title='List Type'>
                        <option value='normal'>{{ list_types.normal }}</option>
                        <option value='faster'>{{ list_types.faster }}</option>
                        <option value='compact'>{{ list_types.compact }}</option>
                        <option value='really_compact'>{{ list_types.rcompact }}</option>
                      </select>
                    </default>
                    <default variable="form.deprecated" value='&form.deprecated;'>
                      <label for='deprecated_'>
                        <input type='checkbox' name='deprecated' value='1'
                               id='deprecated_' data-toggle-submit=''
                               data-add-variable='reload=1' />
                        <span>Include deprecated modules</span>
                      </label>
                    </default>
                  </div>
                </form>
              </div>

              {{#search_form}}
                <div class='flex flex-shrink' id='mod-search'>
                  <form>
                    <roxen-wizard-id-variable />
                    <input type='search' size='30' name='mod_query'
                           id='mod-query' placeholder='Search modules...'>
                    <i class='fa fa-spinner fa-pulse hidden' id='mod-spinner'></i>
                  </form>
                  <script>
                    var e = document.createElement('script');
                    e.setAttribute('async', true);
                    e.setAttribute('src', '/js/find-module.js');
                    document.getElementsByTagName('script')[0]
                      .parentNode.appendChild(e);
                  </script>
                </div>
              {{/search_form}}

              <div class='flex flex-fill'></div>

              <div class='flex flex-shrink'>
                <link-gbutton type='reload'
                  href='add_module.pike?config=&form.config:http;&amp;reload_module_list=yes&amp;method={{ method }}&amp;&usr.set-wiz-id;&amp;deprecated=&form.deprecated;'
                >{{ button.reload }}</link-gbutton>
                <link-gbutton type='cancel' href='site.html/&form.config;/'
                >{{ button.cancel }}</link-gbutton>
              </div>
            </div><!-- flex-row -->
          </if>
          {{ #content }}
            {{ &content }} <!-- No HTML escape -->
          {{ /content }}
        </st-page>
      </subtablist>
    </cv-split>
  </content>
</tmpl>
