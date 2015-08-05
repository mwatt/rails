//= link ./javascripts/application.js
//= link ./stylesheets/application.css
<% if mountable? -%>
//= link <%= namespaced_name %>_manifest.js
<% end -%>
