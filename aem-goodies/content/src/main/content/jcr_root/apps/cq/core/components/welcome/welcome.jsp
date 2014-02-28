<%@page session="false"
        contentType="text/html; charset=utf-8"
        import="java.util.ArrayList,
                java.util.Arrays,
                java.util.Calendar,
                java.util.Collection,
                java.util.List,
                java.util.ResourceBundle,
                javax.jcr.Node,
                javax.jcr.NodeIterator,
                javax.jcr.RepositoryException,
                javax.jcr.Session,
                javax.jcr.query.QueryManager,
                com.adobe.cq.history.api.HistoryEntry,
                com.adobe.cq.history.api.HistoryService,
                com.adobe.cq.history.filter.ResourceTypesFilter,
                com.day.cq.commons.Console,
                com.day.cq.commons.ConsoleUtil,
                com.day.cq.commons.ProductInfo,
                com.day.cq.commons.ProductInfoService,
                com.day.cq.commons.date.RelativeTimeFormat,
                com.day.cq.i18n.I18n,
                com.day.cq.rewriter.linkchecker.LinkCheckerSettings,
                com.day.cq.security.Authorizable,
                com.day.cq.wcm.api.Page,
                com.day.cq.xss.ProtectionContext,
                com.day.cq.xss.XSSProtectionException,
                com.day.cq.xss.XSSProtectionService,
                com.day.text.Text,
                org.apache.commons.lang3.StringEscapeUtils,
                org.apache.sling.api.SlingHttpServletRequest,
                org.apache.sling.api.resource.ResourceUtil"%><%
%><%@include file="/apps/aem-goodies/global.jsp"%><%

    final ResourceBundle resourceBundle = slingRequest.getResourceBundle(null);
    final I18n i18n = new I18n(resourceBundle);
    final String contextPath = request.getContextPath();

    String title = i18n.getVar(properties.get("jcr:title", ResourceUtil.getName(resource)));

    Session session = resourceResolver.adaptTo(Session.class);
    Authorizable auth = resourceResolver.adaptTo(Authorizable.class);

    String name = auth == null ? null : auth.getName();
    if (name == null) {
        // workaround if user manager service is not ready yet.
        name = session.getUserID();
    }

    HistoryService history = sling.getService(HistoryService.class);

    XSSProtectionService xssService = sling.getService(XSSProtectionService.class);
    if (xssService != null) {
        try {
            name = xssService.protectForContext(ProtectionContext.PLAIN_HTML_CONTENT, name);
        } catch (XSSProtectionException e) {
            // Ignored
        }
    }

    String[] searchPath = resourceResolver.getSearchPath();
    QueryManager qm = session.getWorkspace().getQueryManager();
    ConsoleUtil consoleUtil = new ConsoleUtil(qm, null, searchPath);

    String basePath = resource.getPath();
    String cssPath = getOverlayCssPath(resource, "/welcome.css");
    String ieCssPath = getOverlayCssPath(resource, "/welcome_ie.css");
    String mobileCssPath = getOverlayCssPath(resource, "/welcome_touch.css");

%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title><%= StringEscapeUtils.escapeHtml4(title) %></title>

    <link rel="shortcut icon" href="welcome/favicon.ico" type="image/vnd.microsoft.icon">
    <link rel="icon" href="welcome/favicon.ico" type="image/vnd.microsoft.icon">
    <link rel="stylesheet" type="text/css" href="<%= contextPath %><%= cssPath %>">

    <!--[if IE]>
        <link rel="stylesheet" type="text/css" href="<%= contextPath %><%= ieCssPath%>">
    <![endif]-->

    <cq:includeClientLib categories="cq.clientlibrarymanager,cq.shared"/>

    <script type="text/javascript" src="login/login.js"></script>
    <script type="text/javascript">
        if(navigator.userAgent.match(/Mobile/i) || navigator.userAgent.match(/BlackBerry/i)) {
            document.write('<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">');
            document.write('<link rel="stylesheet" type="text/css" href="<%= contextPath %><%= mobileCssPath %>">');
        }
    </script>
</head>
<%
Resource bgImg = resourceResolver.resolve("/libs/cq/core/content/login/bg/background.png");
String styleBody = "";
if(bgImg != null && bgImg.getResourceType() != Resource.RESOURCE_TYPE_NON_EXISTING) {
    styleBody = "style=\"background-color:#000; background-image:url("+bgImg.getPath()+"); background-position: 0 0; background-repeat: no-repeat;\"";
}
%>
<body>
<div id="wrapper">
    <div id="header">
        <div id="tag"></div><%
    Resource search = resource.getResourceResolver().getResource(basePath + "/search");
    if (search != null) {
        String action = "", param = "", hiddenParams = "", querySuffix = "", target = "_self";
        Node searchNode = search.adaptTo(Node.class);
        if (searchNode != null) {
           action = searchNode.hasProperty("action") ? searchNode.getProperty("action").getString() : resource.getPath();
           param = searchNode.hasProperty("param") ? searchNode.getProperty("param").getString() : "q";
           hiddenParams = searchNode.hasProperty("hiddenParams") ? searchNode.getProperty("hiddenParams").getString() : "";
           querySuffix = searchNode.hasProperty("querySuffix") ? searchNode.getProperty("querySuffix").getString() : "";
           target = searchNode.hasProperty("target") ? searchNode.getProperty("target").getString() : "_self";
        }
        %><div id="search">
            <form target="<%= target %>" action="<%= action %>">
                <div id="search-input">
                    <input type="text" name="<%= param %>" placeholder="<%= i18n.get("Search", "welcome screen") %>" />
                </div>
                <div id="welcome-message"><%= i18n.get("Welcome, {0}.", "welcome screen", name) %>
                   (<a href="<%= contextPath %>/libs/cq/core/content/login.logout.html" class="signout"><%= i18n.get("sign out", "welcome screen") %></a>)
               </div>
            </form>
        </div><%
    }
        %><div id="product"></div>
    </div>
    <div id="apps">
    <%
    int i = 1;
    final RelativeTimeFormat relativeTimeFormat = new RelativeTimeFormat(RelativeTimeFormat.SHORT, resourceBundle);
    for (Console app : consoleUtil.getPaths()) {
        if (i > 6) i = 1;
        String appPath = app.getVanityPath()  != null ? app.getVanityPath() : app.getPath();
        String appName = app.getAppName()     != null ? i18n.getVar(app.getAppName()) : i18n.get("CQ5 Console");
        String appDesc = app.getDescription() != null ? i18n.getVar(app.getDescription()) : "";
        String iconClass = app.getIconClass() != null ? app.getIconClass() : "siteadmin";
        ValueMap consoleProps = ResourceUtil.getValueMap(resourceResolver.getResource(app.getPath()));
        boolean showHistory = history != null && consoleProps.get("historyShow", false);
        %><div class="box"><%
            %><div class="boxcontent" id="box_<%= i %>"><%
                %><a href="<%= request.getContextPath() %><%= appPath %>" title="<%= appName %>"><%
                    %><div class="icon <%= iconClass %>"><%
                        %><div class="title"><%= appName%></div><%
                        %><div class="description"><%= appDesc%></div><%
                    %></div><%
                %></a><%
            %></div><%
            if (showHistory) {
                Collection<String> filtered = Arrays.asList(consoleProps.get("historyResourceTypes", new String[0]));
                Long historyCount = consoleProps.get("historyCount", 10L);
                Collection<HistoryEntry> historyEntries = history.readEntries(resourceResolver, session.getUserID(), historyCount.intValue(), new ResourceTypesFilter(filtered));
                %><span class="history-toggle"><%= xssAPI.encodeForHTML(consoleProps.get("historyTitle", i18n.get("Recently used items"))) %></span><%
                %><div class="history-entries">
                    <ul><%
                        if (!historyEntries.isEmpty()) {
                            String historyLink = consoleProps.get("historyLink", null);
                            for (HistoryEntry he : historyEntries) {
                                Resource historyRes = resourceResolver.getResource(he.getResourcePath());
                                if (historyRes != null) {
                                    String hetTitle = Text.getName(he.getResourcePath());
                                    String actionTitle = he.getAction().equals(HistoryEntry.Action.EDIT)
                                            ? i18n.get("Edit", "History action label when resource has been edited")
                                            : i18n.get("View", "History action label when resource has been viewed");
                                    if (he.getResourceTypes().contains("cq:Page")) {
                                        Page historyPage = historyRes.adaptTo(Page.class);
                                        if (historyPage != null) {
                                            hetTitle = historyPage.getTitle();
                                        }
                                    }
                                    %><li>
                                        <span class="history-item-resource history-item-resource-<%= he.getAction().toString().toLowerCase() %>" title="<%= actionTitle %>"><%
                                            if (historyLink != null) {
                                                %><a href="<%= historyLink.replaceAll("\\$\\{resource.path\\}", he.getResourcePath()) %>" title="<%= xssAPI.encodeForHTML(he.getResourcePath()) %>" target="_blank"><%= xssAPI.encodeForHTML(hetTitle) %></a><%
                                            } else {
                                                %><%= xssAPI.encodeForHTML(hetTitle) %><%
                                            }
                                        %></span>
                                        <span class="history-item-date"><%= relativeTimeFormat.format(he.getDate().getTimeInMillis(), true) %></span><%
                                    %></li><%
                                }
                            }
                        } else {
                            %><li class="history-empty"><%= consoleProps.get("historyEmptyText", i18n.get("No items")) %></li><%
                        }
                    %></ul>
                </div><%
            }
        %></div><%
        i++;
    }
    consoleUtil.dispose();
    
    String prodName = "";
    String prodVersion = "";
    ProductInfoService piService = sling.getService(ProductInfoService.class);
    if (piService != null) {
        ProductInfo pi = piService.getInfo();
        prodName = pi.getName();
        prodVersion = pi.getVersion().toString();
    }
    String cq5Info = i18n.get("{0}, Version {1}", "Welcome screen footer: {productName}, Version {productVersion}", prodName, prodVersion);
    String licenseInfo = i18n.get("License Information");
    String licenseURL = "/system/granite/license/"; // todo: translate
    String copyright = i18n.get("&copy; 1997-{0} Adobe Systems Incorporated. All Rights Reserved.", null, ""+Calendar.getInstance().get(Calendar.YEAR));
    
    out.flush();
    LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(true);
    %>
    <div id="productinfo">
        <%= cq5Info %> | <a href="<%= licenseURL %>" title="<%= licenseInfo %>"><%= licenseInfo %></a><br>
        <%= copyright %>
    </div>
	<div id="productinfo">
        <aemg:codebaseDetails />
    </div>
    <%
    out.flush();
    LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(false);
    %>
    </div>
    <div class="right">
        <div class="right-bg">
                <div class="resourcebox"><%
                basePath = basePath.substring(basePath.indexOf("/")+1);
                basePath = basePath.substring(basePath.indexOf("/")+1);

                Resource features = resource.getResourceResolver().getResource(basePath + "/features");
                Resource resources = resource.getResourceResolver().getResource(basePath + "/resources");
                Resource docs = resource.getResourceResolver().getResource(basePath + "/docs");

                if (showFeatureBox(features, resources, search)) {

                   /*---< resources >-----------------------------------------------------*/
                   if (resources != null) {
                       out.flush();
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreExternals(true);
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(true);
                       List<String[]> links = getLinks(slingRequest, resources, i18n);
                       String separator = "";
                       %><div id="resources"><%
                       for (String[] link : links) {
                           %><%= separator %><%
                           %><div class="resource"><a href="<%= link[0]%>" title="<%= link[1] %>" target="<%= link[0].startsWith("http") ? "_blank" : "_self" %>"><%= link[1] %></a><%
                               if (!"".equals(link[2])) {
                           %><div class="description"><%= link[2] %></div><%
                               }
                           %></div><%
                           if ("".equals(separator)) {
                               separator = "<div class=\"separator\">&nbsp;</div>";
                           }
                       }
                       out.flush();
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreExternals(false);
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(false);
                       %></div><%
                    }

                   /*---< docs >-----------------------------------------------------*/
                   if (docs != null) {
                       out.flush();
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreExternals(true);
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(true);
                       List<String[]> links = getLinks(slingRequest, docs, i18n);
                       String separator = "";
                       %><div id="docs"><%
                       for (String[] link : links) {
                           %><%= separator %><%
                           %><div class="docs"><a href="<%= link[0]%>" title="<%= link[1] %>" target="<%= link[0].startsWith("http") ? "_blank" : "_self" %>"><%= link[1] %></a><%
                               if (!"".equals(link[2])) {
                           %><div class="description"><%= link[2] %></div><%
                               }
                           %></div><%
                           if ("".equals(separator)) {
                               separator = "<div class=\"separator\">&nbsp;</div>";
                           }
                       }
                       out.flush();
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreExternals(false);
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(false);
                       %></div><%
                   }

                   /*---< features >-----------------------------------------------------*/
                   if (features != null) {
                       out.flush();
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreExternals(true);
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(true);
                       List<String[]> links = getLinks(slingRequest, features, i18n);
                       String separator = "";
                       %><div id="features"><%
                       for (String[] link : links) {
                           %><%= separator %><%
                           %><div class="feature"><a href="<%= link[0]%>" title="<%= link[1] %>" target="<%= link[0].startsWith("http") ? "_blank" : "_self" %>"><%= link[1] %></a><%
                               if (!"".equals(link[2])) {
                           %><div class="description"><%= link[2] %></div><%
                               }
                           %></div><%
                           if ("".equals(separator)) {
                               separator = "<div class=\"separator\">&nbsp;</div>";
                           }
                       }
                       out.flush();
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreExternals(false);
                       LinkCheckerSettings.fromRequest(slingRequest).setIgnoreInternals(false);
                       %></div><%
                    }

                }
                %>
                <div id="productclaim" onclick="window.open('http://marketing.adobe.com');"></div>
            </div>
        </div>
    </div>
</div>
<script type="text/javascript">
    $CQ(document).ready(function() {
        $CQ(".history-toggle").on("click", function(e) {
            var span = $CQ(this);
            span.toggleClass("history-toggle-expanded");
            e.preventDefault();
            e.stopPropagation();
            $CQ(this).closest(".box").find(".history-entries ul").slideToggle("medium", function() {
                if ($CQ(this).is(":visible")) {
                    $CQ(this).css("display", "inline-block");
                }
            });
        });
    });
</script>
</body>
</html><%
%><%@include file="/libs/cq/core/components/welcome/functions.jsp"%>
