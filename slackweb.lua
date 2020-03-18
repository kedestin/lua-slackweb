local requests = require('requests')
local mime = {
    json = 'application/json',
    urlenc = 'application/x-www-form-urlencoded'
}

local BASEURL = "https://slack.com/api/"

function required(rrs)
    return function(args)
        for _, r in ipairs(rrs) do
            if args[r] == nil then
                error("SlackWeb: missing required argument '" .. r .. "'")
            end
        end
        return args
    end
end

function get(url, contenttype, payloadfunc)
    return sendrequest(function(args) return requests.get(args) end, url,
                       contenttype, payloadfunc)
end

function post(url, contenttype, payloadfunc)
    return sendrequest(function(args) return requests.post(args) end, url,
                       contenttype, payloadfunc)
end

function sendrequest(requestfunc, url, contenttype, payloadfunc)
    local headers = {['Content-Type'] = contenttype}
    local absurl = BASEURL .. url
    local tosend = {absurl, headers = headers}
    local payload_location = contenttype ~= "application/json" and "params" or
                                 "data"
    return function(args)
        tosend[payload_location] = payloadfunc(args)
        if tosend[payload_location].token ~= nil then
            tosend.headers.Authorization =
                "Bearer " .. tosend[payload_location].token
            tosend[payload_location].token = nil
        end
        response = requestfunc(tosend).json()
        if response.ok ~= true then
            error("SlackWeb: SlackError: " .. response.error)
        end
        return response
    end
end

SlackWeb = {}

SlackWeb.conversations = {
    archive = post("conversations.archive", mime.json,
                   required {"token", "channel"}),
    members = get("conversations.members", mime.urlenc,
                  required {"token", "channel"}),
    history = get("conversations.history", mime.urlenc,
                  required {"token", "channel"}),
    setTopic = post("conversations.setTopic", mime.json,
                    required {"token", "channel", "topic"}),
    create = post("conversations.create", mime.json, required {"token", "name"}),
    rename = post("conversations.rename", mime.json,
                  required {"token", "channel", "name"}),
    unarchive = post("conversations.unarchive", mime.json,
                     required {"token", "channel"}),
    invite = post("conversations.invite", mime.json,
                  required {"token", "channel", "users"}),
    info = get("conversations.info", mime.urlenc, required {"token", "channel"}),
    open = post("conversations.open", mime.json, required {"token"}),
    replies = get("conversations.replies", mime.urlenc,
                  required {"token", "channel", "ts"}),
    leave = post("conversations.leave", mime.json, required {"token", "channel"}),
    setPurpose = post("conversations.setPurpose", mime.json,
                      required {"token", "channel", "purpose"}),
    join = post("conversations.join", mime.json, required {"token", "channel"}),
    list = get("conversations.list", mime.urlenc, required {"token"}),
    close = post("conversations.close", mime.json, required {"token", "channel"}),
    kick = post("conversations.kick", mime.json,
                required {"token", "channel", "user"})
}

SlackWeb.users = {
    conversations = get("users.conversations", mime.urlenc, required {"token"}),
    list = get("users.list", mime.urlenc, required {"token"}),
    setPresence = post("users.setPresence", mime.json,
                       required {"token", "presence"}),
    info = get("users.info", mime.urlenc, required {"token", "user"}),
    setActive = post("users.setActive", mime.json, required {"token"}),
    setPhoto = post("users.setPhoto", mime.urlenc, required {"token", "image"}),
    getPresence = get("users.getPresence", mime.urlenc,
                      required {"token", "user"}),
    deletePhoto = get("users.deletePhoto", mime.urlenc, required {"token"}),
    lookupByEmail = get("users.lookupByEmail", mime.urlenc,
                        required {"token", "email"}),
    identity = get("users.identity", mime.urlenc, required {"token"})
}

SlackWeb.users.profile = {
    get = get("users.profile.get", mime.urlenc, required {"token"}),
    set = post("users.profile.set", mime.json, required {"token"})
}

SlackWeb.team = {
    info = get("team.info", mime.urlenc, required {"token"}),
    billableInfo = get("team.billableInfo", mime.urlenc, required {"token"}),
    integrationLogs = get("team.integrationLogs", mime.urlenc,
                          required {"token"}),
    accessLogs = get("team.accessLogs", mime.urlenc, required {"token"})
}

SlackWeb.team.profile = {
    get = get("team.profile.get", mime.urlenc, required {"token"})
}

SlackWeb.bots = {info = get("bots.info", mime.urlenc, required {"token"})}

SlackWeb.search = {
    files = get("search.files", mime.urlenc, required {"token", "query"}),
    messages = get("search.messages", mime.urlenc, required {"token", "query"}),
    all = get("search.all", mime.urlenc, required {"token", "query"})
}

SlackWeb.stars = {
    remove = post("stars.remove", mime.json, required {"token"}),
    list = get("stars.list", mime.urlenc, required {"token"}),
    add = post("stars.add", mime.json, required {"token"})
}

SlackWeb.files = {
    list = get("files.list", mime.urlenc, required {"token"}),
    revokePublicURL = post("files.revokePublicURL", mime.json,
                           required {"token", "file"}),
    sharedPublicURL = post("files.sharedPublicURL", mime.json,
                           required {"token", "file"}),
    delete = post("files.delete", mime.json, required {"token", "file"}),
    info = get("files.info", mime.urlenc, required {"token", "file"}),
    upload = post("files.upload", mime.urlenc, required {"token"})
}

SlackWeb.files.comments = {
    delete = post("files.comments.delete", mime.json,
                  required {"token", "file", "id"})
}

SlackWeb.files.remote = {
    remove = get("files.remote.remove", mime.urlenc, required {"token"}),
    list = get("files.remote.list", mime.urlenc, required {"token"}),
    update = get("files.remote.update", mime.urlenc, required {"token"}),
    share = get("files.remote.share", mime.urlenc,
                required {"token", "channels"}),
    info = get("files.remote.info", mime.urlenc, required {"token"}),
    add = get("files.remote.add", mime.urlenc,
              required {"token", "external_id", "external_url", "title"})
}

SlackWeb.rtm = {
    connect = get("rtm.connect", mime.urlenc, required {"token"}),
    start = get("rtm.start", mime.urlenc, required {"token"})
}

SlackWeb.admin = {}

SlackWeb.admin.teams = {
    list = post("admin.teams.list", mime.json, required {"token"}),
    create = post("admin.teams.create", mime.json,
                  required {"token", "team_domain", "team_name"})
}

SlackWeb.admin.teams.admins = {
    list = get("admin.teams.admins.list", mime.urlenc,
               required {"token", "team_id"})
}

SlackWeb.admin.teams.settings = {
    info = post("admin.teams.settings.info", mime.json,
                required {"token", "team_id"}),
    setDiscoverability = post("admin.teams.settings.setDiscoverability",
                              mime.json,
                              required {"token", "discoverability", "team_id"}),
    setName = post("admin.teams.settings.setName", mime.json,
                   required {"token", "name", "team_id"}),
    setDescription = post("admin.teams.settings.setDescription", mime.json,
                          required {"token", "description", "team_id"}),
    setIcon = get("admin.teams.settings.setIcon", mime.urlenc,
                  required {"token", "image_url", "team_id"}),
    setDefaultChannels = get("admin.teams.settings.setDefaultChannels",
                             mime.urlenc,
                             required {"token", "channel_ids", "team_id"})
}

SlackWeb.admin.teams.owners = {
    list = get("admin.teams.owners.list", mime.urlenc,
               required {"token", "team_id"})
}

SlackWeb.admin.conversations = {
    setTeams = post("admin.conversations.setTeams", mime.json,
                    required {"token", "channel_id"})
}

SlackWeb.admin.apps = {
    approve = post("admin.apps.approve", mime.json, required {"token"}),
    restrict = post("admin.apps.restrict", mime.json, required {"token"})
}

SlackWeb.admin.apps.approved = {
    list = get("admin.apps.approved.list", mime.urlenc, required {"token"})
}

SlackWeb.admin.apps.requests = {
    list = get("admin.apps.requests.list", mime.urlenc, required {"token"})
}

SlackWeb.admin.apps.restricted = {
    list = get("admin.apps.restricted.list", mime.urlenc, required {"token"})
}

SlackWeb.admin.emoji = {
    remove = get("admin.emoji.remove", mime.urlenc, required {"token", "name"}),
    addAlias = get("admin.emoji.addAlias", mime.urlenc,
                   required {"token", "alias_for", "name"}),
    list = get("admin.emoji.list", mime.urlenc, required {"token"}),
    rename = get("admin.emoji.rename", mime.urlenc,
                 required {"token", "name", "new_name"}),
    add = get("admin.emoji.add", mime.urlenc, required {"token", "name", "url"})
}

SlackWeb.admin.users = {
    remove = post("admin.users.remove", mime.json,
                  required {"token", "team_id", "user_id"}),
    list = post("admin.users.list", mime.json, required {"token", "team_id"}),
    setExpiration = post("admin.users.setExpiration", mime.json, required {
        "token", "expiration_ts", "team_id", "user_id"
    }),
    invite = post("admin.users.invite", mime.json,
                  required {"token", "channel_ids", "email", "team_id"}),
    assign = post("admin.users.assign", mime.json,
                  required {"token", "team_id", "user_id"}),
    setOwner = post("admin.users.setOwner", mime.json,
                    required {"token", "team_id", "user_id"}),
    setAdmin = post("admin.users.setAdmin", mime.json,
                    required {"token", "team_id", "user_id"}),
    setRegular = post("admin.users.setRegular", mime.json,
                      required {"token", "team_id", "user_id"})
}

SlackWeb.admin.users.session = {
    reset = post("admin.users.session.reset", mime.json,
                 required {"token", "user_id"})
}

SlackWeb.admin.inviteRequests = {
    approve = post("admin.inviteRequests.approve", mime.json,
                   required {"token", "invite_request_id"}),
    list = post("admin.inviteRequests.list", mime.json, required {"token"}),
    deny = post("admin.inviteRequests.deny", mime.json,
                required {"token", "invite_request_id"})
}

SlackWeb.admin.inviteRequests.denied = {
    list = post("admin.inviteRequests.denied.list", mime.json,
                required {"token"})
}

SlackWeb.admin.inviteRequests.approved =
    {
        list = post("admin.inviteRequests.approved.list", mime.json,
                    required {"token"})
    }

SlackWeb.views = {
    push = post("views.push", mime.json,
                required {"token", "trigger_id", "view"}),
    open = post("views.open", mime.json,
                required {"token", "trigger_id", "view"}),
    update = post("views.update", mime.json, required {"token", "view"}),
    publish = post("views.publish", mime.json,
                   required {"token", "user_id", "view"})
}

SlackWeb.pins = {
    remove = post("pins.remove", mime.json, required {"token", "channel"}),
    list = get("pins.list", mime.urlenc, required {"token", "channel"}),
    add = post("pins.add", mime.json, required {"token", "channel", "timestamp"})
}

SlackWeb.migration = {
    exchange = get("migration.exchange", mime.urlenc,
                   required {"token", "users"})
}

SlackWeb.auth = {
    test = post("auth.test", mime.json, required {"token"}),
    revoke = get("auth.revoke", mime.urlenc, required {"token"})
}

SlackWeb.chat = {
    postMessage = post("chat.postMessage", mime.json,
                       required {"token", "channel", "text"}),
    scheduleMessage = post("chat.scheduleMessage", mime.json,
                           required {"token", "channel", "post_at", "text"}),
    update = post("chat.update", mime.json,
                  required {"token", "channel", "text", "ts"}),
    unfurl = post("chat.unfurl", mime.json,
                  required {"token", "channel", "ts", "unfurls"}),
    getPermalink = get("chat.getPermalink", mime.urlenc,
                       required {"token", "channel", "message_ts"}),
    postEphemeral = post("chat.postEphemeral", mime.json, required {
        "token", "attachments", "channel", "text", "user"
    }),
    delete = post("chat.delete", mime.json, required {"token", "channel", "ts"}),
    meMessage = post("chat.meMessage", mime.json,
                     required {"token", "channel", "text"}),
    deleteScheduledMessage = post("chat.deleteScheduledMessage", mime.json,
                                  required {
        "token", "channel", "scheduled_message_id"
    })
}

SlackWeb.chat.scheduledMessages = {
    list = post("chat.scheduledMessages.list", mime.json, required {"token"})
}

SlackWeb.dnd = {
    endDnd = post("dnd.endDnd", mime.json, required {"token"}),
    setSnooze = get("dnd.setSnooze", mime.urlenc,
                    required {"token", "num_minutes"}),
    info = get("dnd.info", mime.urlenc, required {"token"}),
    teamInfo = get("dnd.teamInfo", mime.urlenc, required {"token", "users"}),
    endSnooze = post("dnd.endSnooze", mime.json, required {"token"})
}

SlackWeb.usergroups = {
    list = get("usergroups.list", mime.urlenc, required {"token"}),
    enable = post("usergroups.enable", mime.json,
                  required {"token", "usergroup"}),
    create = post("usergroups.create", mime.json, required {"token", "name"}),
    update = post("usergroups.update", mime.json,
                  required {"token", "usergroup"}),
    disable = post("usergroups.disable", mime.json,
                   required {"token", "usergroup"})
}

SlackWeb.usergroups.users = {
    update = post("usergroups.users.update", mime.json,
                  required {"token", "usergroup", "users"}),
    list = get("usergroups.users.list", mime.urlenc,
               required {"token", "usergroup"})
}

SlackWeb.reactions = {
    remove = post("reactions.remove", mime.json, required {"token", "name"}),
    get = get("reactions.get", mime.urlenc, required {"token"}),
    list = get("reactions.list", mime.urlenc, required {"token"}),
    add = post("reactions.add", mime.json,
               required {"token", "channel", "name", "timestamp"})
}

SlackWeb.mpim = {
    list = get("mpim.list", mime.urlenc, required {"token"}),
    open = post("mpim.open", mime.json, required {"token", "users"}),
    replies = get("mpim.replies", mime.urlenc,
                  required {"token", "channel", "thread_ts"}),
    history = get("mpim.history", mime.urlenc, required {"token", "channel"}),
    mark = post("mpim.mark", mime.json, required {"token", "channel", "ts"}),
    close = post("mpim.close", mime.json, required {"token", "channel"})
}

SlackWeb.reminders = {
    complete = post("reminders.complete", mime.json,
                    required {"token", "reminder"}),
    list = get("reminders.list", mime.urlenc, required {"token"}),
    delete = post("reminders.delete", mime.json, required {"token", "reminder"}),
    info = get("reminders.info", mime.urlenc, required {"token", "reminder"}),
    add = post("reminders.add", mime.json, required {"token", "text", "time"})
}

SlackWeb.dialog = {
    open = post("dialog.open", mime.json,
                required {"token", "dialog", "trigger_id"})
}

SlackWeb.api = {test = post("api.test", mime.json, required {})}

SlackWeb.channels = {
    archive = post("channels.archive", mime.json, required {"token", "channel"}),
    history = get("channels.history", mime.urlenc, required {"token", "channel"}),
    setTopic = post("channels.setTopic", mime.json,
                    required {"token", "channel", "topic"}),
    create = post("channels.create", mime.json, required {"token", "name"}),
    rename = post("channels.rename", mime.json,
                  required {"token", "channel", "name"}),
    unarchive = post("channels.unarchive", mime.json,
                     required {"token", "channel"}),
    invite = post("channels.invite", mime.json,
                  required {"token", "channel", "user"}),
    info = get("channels.info", mime.urlenc, required {"token", "channel"}),
    replies = get("channels.replies", mime.urlenc,
                  required {"token", "channel", "thread_ts"}),
    leave = post("channels.leave", mime.json, required {"token", "channel"}),
    setPurpose = post("channels.setPurpose", mime.json,
                      required {"token", "channel", "purpose"}),
    mark = post("channels.mark", mime.json, required {"token", "channel", "ts"}),
    join = post("channels.join", mime.json, required {"token", "name"}),
    list = get("channels.list", mime.urlenc, required {"token"}),
    kick = post("channels.kick", mime.json,
                required {"token", "channel", "user"})
}

SlackWeb.apps = {
    uninstall = get("apps.uninstall", mime.urlenc,
                    required {"token", "client_id", "client_secret"})
}

SlackWeb.apps.permissions = {
    info = get("apps.permissions.info", mime.urlenc, required {"token"}),
    request = get("apps.permissions.request", mime.urlenc,
                  required {"token", "scopes", "trigger_id"})
}

SlackWeb.apps.permissions.users = {
    list = get("apps.permissions.users.list", mime.urlenc, required {"token"}),
    request = get("apps.permissions.users.request", mime.urlenc,
                  required {"token", "scopes", "trigger_id", "user"})
}

SlackWeb.apps.permissions.scopes = {
    list = get("apps.permissions.scopes.list", mime.urlenc, required {"token"})
}

SlackWeb.apps.permissions.resources = {
    list = get("apps.permissions.resources.list", mime.urlenc,
               required {"token"})
}

SlackWeb.im = {
    list = get("im.list", mime.urlenc, required {"token"}),
    open = post("im.open", mime.json, required {"token", "user"}),
    replies = get("im.replies", mime.urlenc,
                  required {"token", "channel", "thread_ts"}),
    history = get("im.history", mime.urlenc, required {"token", "channel"}),
    mark = post("im.mark", mime.json, required {"token", "channel", "ts"}),
    close = post("im.close", mime.json, required {"token", "channel"})
}

SlackWeb.groups = {
    archive = post("groups.archive", mime.json, required {"token", "channel"}),
    createChild = get("groups.createChild", mime.urlenc,
                      required {"token", "channel"}),
    history = get("groups.history", mime.urlenc, required {"token", "channel"}),
    setTopic = post("groups.setTopic", mime.json,
                    required {"token", "channel", "topic"}),
    create = post("groups.create", mime.json, required {"token", "name"}),
    rename = post("groups.rename", mime.json,
                  required {"token", "channel", "name"}),
    unarchive = post("groups.unarchive", mime.json,
                     required {"token", "channel"}),
    invite = post("groups.invite", mime.json,
                  required {"token", "channel", "user"}),
    info = get("groups.info", mime.urlenc, required {"token", "channel"}),
    open = post("groups.open", mime.json, required {"token", "channel"}),
    replies = get("groups.replies", mime.urlenc,
                  required {"token", "channel", "thread_ts"}),
    leave = post("groups.leave", mime.json, required {"token", "channel"}),
    setPurpose = post("groups.setPurpose", mime.json,
                      required {"token", "channel", "purpose"}),
    mark = post("groups.mark", mime.json, required {"token", "channel", "ts"}),
    list = get("groups.list", mime.urlenc, required {"token"}),
    kick = post("groups.kick", mime.json, required {"token", "channel", "user"})
}

SlackWeb.emoji = {list = get("emoji.list", mime.urlenc, required {"token"})}

SlackWeb.oauth = {
    access = post("oauth.access", mime.urlenc,
                  required {"client_id", "client_secret", "code"}),
    token = post("oauth.token", mime.urlenc,
                 required {"client_id", "client_secret", "code"})
}

SlackWeb.oauth.v2 = {
    access = post("oauth.v2.access", mime.urlenc, required {"code"})
}

return SlackWeb
