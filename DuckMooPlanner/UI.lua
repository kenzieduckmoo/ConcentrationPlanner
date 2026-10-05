local _, P = ...
local M=P.Model
local unpack=unpack or table.unpack
local purple={0.68,0.43,0.95}
-- WoW frames cannot be garbage collected. Recycle frames and font strings.
P.dynamicParents={}
local function acquire(parent,kind,template)
    if not P.dynamic then
        if kind=='FontString' then return parent:CreateFontString(nil,'OVERLAY',template) end
        return CreateFrame(kind,nil,parent,template)
    end
    if not parent._dmpPools then
        parent._dmpPools={};parent._dmpUsed={};P.dynamicParents[#P.dynamicParents+1]=parent
    end
    local key=kind..(template or '')
    local pool=parent._dmpPools[key] or {};parent._dmpPools[key]=pool
    local i=(parent._dmpUsed[key] or 0)+1;parent._dmpUsed[key]=i
    local f=pool[i]
    if not f then
        if kind=='FontString' then f=parent:CreateFontString(nil,'OVERLAY',template)
        else f=CreateFrame(kind,nil,parent,template) end
        pool[i]=f
    end
    f:ClearAllPoints();f:Show()
    return f
end
local function label(parent,text,x,y,width,font)
    local f=acquire(parent,'FontString',font or 'GameFontHighlight')
    f:SetFontObject(font or 'GameFontHighlight');f:SetHeight(0);f:SetWordWrap(true);f:SetTextColor(1,1,1);
    f:SetPoint('TOPLEFT',x,y); f:SetWidth(width); f:SetJustifyH('LEFT'); f:SetText(text)
    return f
end
local function roundSurface(f)
    if f._round then return end
    f._round={}
    local radius=6
    local function texture()
        local t=f:CreateTexture(nil,'BACKGROUND');t:SetTexture('Interface/Buttons/WHITE8X8');f._round[#f._round+1]=t;return t
    end
    local center=texture();center:SetPoint('TOPLEFT',radius,-radius);center:SetPoint('BOTTOMRIGHT',-radius,radius)
    local top=texture();top:SetPoint('TOPLEFT',radius,0);top:SetPoint('TOPRIGHT',-radius,0);top:SetHeight(radius)
    local bottom=texture();bottom:SetPoint('BOTTOMLEFT',radius,0);bottom:SetPoint('BOTTOMRIGHT',-radius,0);bottom:SetHeight(radius)
    local left=texture();left:SetPoint('TOPLEFT',0,-radius);left:SetPoint('BOTTOMLEFT',0,radius);left:SetWidth(radius)
    local right=texture();right:SetPoint('TOPRIGHT',0,-radius);right:SetPoint('BOTTOMRIGHT',0,radius);right:SetWidth(radius)
    for _,c in ipairs({{'TOPLEFT',0,0,0,1,0,1},{'TOPRIGHT',0,0,1,0,0,1},{'BOTTOMLEFT',0,0,0,1,1,0},{'BOTTOMRIGHT',0,0,1,0,1,0}}) do
        local t=texture();t:SetTexture('Interface/AddOns/DuckMooPlanner/Media/Corner.tga');t:SetSize(radius,radius);t:SetPoint(c[1],c[2],c[3]);t:SetTexCoord(c[4],c[5],c[6],c[7])
    end
    f:SetBackdrop(nil)
    f.SetBackdropColor=function(self,r,g,b,a)
        self._surfaceColor={r,g,b,a or 1}
        for _,t in ipairs(self._round) do t:SetVertexColor(r,g,b,a or 1) end
    end
    local accent=f:CreateTexture(nil,'BORDER');accent:SetTexture('Interface/Buttons/WHITE8X8');accent:SetWidth(2)
    accent:SetPoint('TOPLEFT',1,-6);accent:SetPoint('BOTTOMLEFT',1,6);f._accent=accent
    f.SetBackdropBorderColor=function(self,r,g,b,a) self._accent:SetVertexColor(r,g,b,a or 1) end
end
local function button(parent,text,x,y,width,action)
    local b=acquire(parent,'Button','BackdropTemplate');roundSurface(b)
    if not b._caption then
        b._caption=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');b._caption:SetPoint('CENTER');b:SetFontString(b._caption)
    end
    b._caption:SetWidth(width-10);b._caption:SetWordWrap(false)
    b:SetSize(width,24);b:SetPoint('TOPLEFT',x,y);b:SetText(text);b:SetScript('OnClick',action)
    b:SetScript('OnMouseDown',function(self) self:SetBackdropColor(.37,.23,.52,1) end)
    b:SetScript('OnMouseUp',function(self) self:SetBackdropColor(.29,.19,.41,1) end)
    b:SetBackdropColor(.18,.12,.26,.97);b:SetBackdropBorderColor(.50,.32,.70,0)
    b:SetScript('OnEnter',function(self) self:SetBackdropColor(.29,.19,.41,1) end)
    b:SetScript('OnLeave',function(self) self:SetBackdropColor(.18,.12,.26,.97) end)
    return b
end
local function panel(parent,name)
    local f=name and CreateFrame('Frame',name,parent,'BackdropTemplate') or acquire(parent,'Frame','BackdropTemplate')
    roundSurface(f)
    f:SetAlpha(1);f:EnableMouse(true);f:SetScript('OnMouseUp',nil);f:SetScript('OnEnter',nil);f:SetScript('OnLeave',nil)
    f:SetBackdropColor(.075,.052,.11,.98);f:SetBackdropBorderColor(.30,.22,.40,0)
    return f
end
local function tooltip(frame,title,lines)
    frame:SetScript('OnEnter',function(self)
        if self._caption then self:SetBackdropColor(.29,.19,.41,1) end
        GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(title)
        for _,s in ipairs(lines) do GameTooltip:AddLine(s,1,1,1,true) end
        GameTooltip:Show()
    end)
    frame:SetScript('OnLeave',function(self) if self._caption then self:SetBackdropColor(.18,.12,.26,.97) end;GameTooltip:Hide() end)
end
local function profession(r)
    if r.expansion and r.expansion~='' and r.expansion~=r.name then return r.name..' ('..r.expansion..')' end
    return r.name
end
local function plain(s) return (s or ''):gsub('|','||'):gsub('[\r\n]+',' ') end
local function description(e)
    if e.kind=='concentration' then return e.ready and 'FULL now' or 'Full '..M.Clock(e.at) end
    if e.kind=='note' then
        if e.overdue then return 'Overdue reminder' end
        if e.projected then return 'Reminder forecast' end
        if e.record.mode=='dailyReset' or e.record.mode=='weeklyReset' then return 'Reminder at '..M.Clock(e.at) end
        return 'Reminder'
    end
    if e.overdue then return 'Patron orders overdue' end
    return e.projected and 'Patron orders (forecast)' or 'Patron orders due'
end
local function editBox(parent,x,y,width)
    local e=CreateFrame('EditBox',nil,parent,'InputBoxTemplate')
    e:SetSize(width,24);e:SetPoint('TOPLEFT',x,y);e:SetAutoFocus(false)
    e:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    e:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
    return e
end
function P.Widget(f) P.widgets[#P.widgets+1]=f;return f end
function P.Text(text,x,y,width,font)
    local holder=P.Widget(acquire(P.content,'Frame'));holder:SetSize(width,20);holder:SetPoint('TOPLEFT',x,y)
    local textLabel=label(holder,text,0,0,width,font);textLabel:SetWordWrap(false)
    return textLabel
end
function P.Clear()
    for _,w in ipairs(P.widgets) do w:Hide() end
    for _,parent in ipairs(P.dynamicParents) do
        parent._dmpUsed={}
        for _,pool in pairs(parent._dmpPools) do for _,child in ipairs(pool) do child:Hide() end end
    end
    P.widgets={}
end
function P.SaveGeometry()
    local s=P.db.settings
    local key=s.compact and 'compact' or 'full'
    s[key..'Size']={P.frame:GetWidth(),P.frame:GetHeight()}
    local point,_,relative,x,y=P.frame:GetPoint()
    s[key..'Position']={point,relative,x,y}
end
function P.ApplyGeometry()
    local f,s=P.frame,P.db.settings
    P.layoutLock=true
    local size=s.compact and (s.compactSize or {340,235}) or (s.fullSize or {800,450})
    local minW,minH=s.compact and 260 or 600,s.compact and 110 or 260
    local maxW,maxH=math.max(minW,UIParent:GetWidth()-20),math.max(minH,UIParent:GetHeight()-20)
    f:SetResizeBounds(minW,minH,maxW,maxH)
    f:SetSize(math.min(maxW,math.max(minW,size[1])),math.min(maxH,math.max(minH,size[2])))
    local pos=s.compact and s.compactPosition or s.fullPosition
    f:ClearAllPoints()
    if pos then f:SetPoint(pos[1],UIParent,pos[2],pos[3],pos[4]) else f:SetPoint('CENTER') end
    f:SetScale(math.min(1,(UIParent:GetWidth()-20)/f:GetWidth(),(UIParent:GetHeight()-20)/f:GetHeight()))
    P.layoutLock=false
end
function P.SetCompact(value)
    if not P.frame then P.BuildUI() end
    if P.db.settings.compact==value then P.Render(true);return end
    P.SaveGeometry()
    P.db.settings.compact=value
    if P.editor then P.editor:Hide() end
    if P.noteEditor then P.noteEditor:Hide() end
    P.ApplyGeometry();P.Render()
end
function P.Layout()
    local f=P.frame
    local compact=P.db.settings.compact==true
    local w,h=f:GetWidth(),f:GetHeight()
    f:SetAlpha(compact and P.db.settings.compactAlpha or P.db.settings.fullAlpha)
    P.title:SetWidth(compact and w-118 or 225)
    P.title:SetText(compact and date('%a, %b %d',GetServerTime()) or 'Concentration Planner')
    for _,b in ipairs(P.tabs) do
        b:SetShown(not compact);b:SetBackdropBorderColor(.75,.48,.95,b.view==P.view and 1 or 0)
    end
    P.search:SetShown(not compact)
    P.heading:SetShown(not compact)
    P.prev:SetShown(not compact and (P.view=='daily' or P.view=='weekly' or P.view=='monthly'))
    P.next:SetShown(P.prev:IsShown());P.today:SetShown(P.prev:IsShown())
    P.compactButton:ClearAllPoints();P.compactButton:SetPoint('TOPRIGHT',-34,-5)
    P.compactButton:SetSize(compact and 70 or 78,22);P.compactButton:SetText(compact and 'Expand' or 'Compact')
    P.addNote:ClearAllPoints();P.addNote:SetPoint('TOPRIGHT',-12,compact and -32 or -60)
    P.addNote:SetSize(compact and 68 or 82,22)
    P.search:ClearAllPoints();P.search:SetPoint('TOPRIGHT',-12,-33);P.search:SetWidth(math.max(110,w-468))
    P.countdown:ClearAllPoints();P.countdown:SetPoint('TOPLEFT',10,compact and -35 or -86);P.countdown:SetWidth(w-(compact and 92 or 20))
    P.heading:SetWidth(w-245)
    local top=compact and 64 or 111
    P.scroll:ClearAllPoints();P.scroll:SetPoint('TOPLEFT',10,-top)
    P.scroll:SetSize(w-38,math.max(30,h-top-19))
    P.content:SetWidth(w-40);P.width=w-40
    P.footer:ClearAllPoints();P.footer:SetPoint('BOTTOMLEFT',10,5);P.footer:SetWidth(w-32)
    P.footer:SetText(compact and '/planner | drag corner to resize' or 'DuckMoo Services | /planner | Local time | drag corner to resize')
end
function P.UpdateCountdown()
    if not P.countdown then return end
    local kind=P.view=='weekly' and not P.db.settings.compact and 'weekly' or 'daily'
    local seconds=P.GetResetSeconds(kind)
    P.countdown:SetText((kind=='weekly' and 'Weekly' or 'Daily')..' reset: '..M.Duration(seconds))
end
function P.BuildUI()
    local f=panel(UIParent,'DuckMooPlannerWindow');P.frame=f
    f:SetFrameStrata('HIGH');f:SetClampedToScreen(true);f:SetMovable(true);f:SetResizable(true)
    f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',f.StartMoving)
    f:SetScript('OnDragStop',function(self) self:StopMovingOrSizing();P.SaveGeometry() end)
    f:Hide()
    f:SetScript('OnHide',function()
        if P.editor then P.editor:Hide() end
        if P.noteEditor then P.noteEditor:Hide() end
        if P.choice then P.choice:Hide() end
        if P.groupEditor then P.groupEditor:Hide() end
        if P.copyDialog then P.copyDialog:Hide() end
        GameTooltip:Hide()
    end)
    local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',0,0)
    P.title=label(f,'DuckMoo Planner',10,-8,225,'GameFontNormalLarge')
    P.tabs={}
    for i,v in ipairs({'daily','weekly','monthly','reminders','settings'}) do
        local view=v
        P.tabs[i]=button(f,view=='reminders' and 'Notes' or view:sub(1,1):upper()..view:sub(2),10+(i-1)*86,-32,82,function() P.Show(view) end)
        P.tabs[i].view=view
    end
    P.compactButton=button(f,'Compact',0,0,78,function() P.SetCompact(not P.db.settings.compact) end)
    P.prev=button(f,'<',10,-60,28,function() P.Navigate(-1) end)
    P.today=button(f,'Today',42,-60,64,function()
        local today=M.Day(GetServerTime());P.followToday=true;P.selectedDay=today;P.month=today;P.weekOffset=0;P.Render()
    end)
    P.next=button(f,'>',110,-60,28,function() P.Navigate(1) end)
    P.addNote=button(f,'+ Note',0,0,82,function() P.NoteEditor() end)
    P.search=editBox(f,0,0,180);P.search:SetMaxLetters(80)
    P.search:SetScript('OnTextChanged',function(self) P.filter=self:GetText();if P.content then P.Render() end end)
    tooltip(P.search,'Filter characters / professions / notes',{'Type part of a character, realm, profession, expansion or note.'})
    P.heading=label(f,'',150,-65,540,'GameFontNormal')
    P.countdown=label(f,'',10,-86,740,'GameFontHighlightSmall')
    P.scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
    P.content=CreateFrame('Frame',nil,P.scroll);P.content:SetSize(760,1);P.scroll:SetScrollChild(P.content)
    P.footer=label(f,'',10,0,740,'GameFontDisableSmall')
    local grip=CreateFrame('Button',nil,f);P.resizeGrip=grip;grip:SetPoint('BOTTOMRIGHT',-1,1);grip:SetSize(16,16)
    grip:SetNormalTexture('Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up')
    grip:SetHighlightTexture('Interface/ChatFrame/UI-ChatIM-SizeGrabber-Highlight')
    grip:SetPushedTexture('Interface/ChatFrame/UI-ChatIM-SizeGrabber-Down')
    grip:SetScript('OnMouseDown',function(_,mouse) if mouse=='LeftButton' then P.resizing=true;f:StartSizing('BOTTOMRIGHT') end end)
    grip:SetScript('OnMouseUp',function() f:StopMovingOrSizing();P.resizing=false;P.SaveGeometry();P.Render(true) end)
    f:SetScript('OnSizeChanged',function()
        if P.layoutLock or not P.content or P.resizePending then return end
        P.resizePending=true
        C_Timer.After(.05,function() P.resizePending=false;if P.frame:IsShown() then P.Render(true) end end)
    end)
    table.insert(UISpecialFrames,'DuckMooPlannerWindow')
    P.widgets={};P.ApplyGeometry();P.Layout()
end
function P.Navigate(delta)
    if P.view=='monthly' then
        local d=date('*t',P.month);P.month=time({year=d.year,month=d.month+delta,day=1,hour=0,min=0,sec=0})
    elseif P.view=='weekly' then P.weekOffset=P.weekOffset+delta
    elseif P.view=='daily' then P.followToday=false;P.selectedDay=M.AddDays(P.selectedDay,delta) end
    P.Render()
end
function P.EventRow(e,y)
    local w=P.width
    local row=P.Widget(panel(P.content));row:SetSize(w,40);row:SetPoint('TOPLEFT',0,-y)
    if e.ready then row:SetBackdropBorderColor(.25,.8,.5,1)
    elseif e.kind=='patron' then row:SetBackdropBorderColor(.9,.65,.25,1)
    elseif e.kind=='note' then row:SetBackdropBorderColor(unpack(purple)) end
    if e.kind=='note' then
        local text=label(row,plain(e.record.text),8,-5,w-92);text:SetWordWrap(false)
        label(row,description(e),8,-23,w-92,'GameFontHighlightSmall')
        if not e.projected and e.record.due<=GetServerTime() then
            button(row,'Dismiss',w-78,-8,70,function() P.DismissNote(e.record) end)
        end
        tooltip(row,plain(e.record.text),{description(e),'Click + Note or the Notes tab to manage custom reminders.'})
        return
    end
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[P.db.characters[e.guid].class]
    local name=label(row,e.character,8,-5,math.floor(w*.43))
    name:SetWordWrap(false);if color then name:SetTextColor(color.r,color.g,color.b) end
    local prof=label(row,profession(e.record),math.floor(w*.44),-5,w-math.floor(w*.44)-85,'GameFontHighlightSmall');prof:SetWordWrap(false)
    label(row,description(e),8,-23,w-90,'GameFontHighlightSmall')
    if e.kind=='patron' and not e.projected and M.PatronDue(e.record,GetServerTime(),P.GetResetSeconds('daily')) then
        button(row,'Done',w-72,-8,64,function() M.Complete(e.record,GetServerTime());P.Render(true) end)
    end
    local r=e.record;local amount=M.Current(r,GetServerTime())
    local lines={description(e),'Last observed: '..(r.observedAt and date('%b %d, %Y',r.observedAt)..' '..M.Clock(r.observedAt) or 'Unknown')}
    if amount then lines[#lines+1]=string.format('Concentration: %d / %d',math.floor(amount),r.max) end
    lines[#lines+1]='Offline Concentration is projected from the last snapshot.'
    tooltip(row,e.character..' '..profession(r),lines)
end
function P.Empty(y) P.Text('Nothing due. Crafting gremlins on break.',8,-y,P.width-16,'GameFontHighlightSmall') end
function P.Daily(now)
    local first=M.Day(P.selectedDay or now);local last=M.AddDays(first,1)
    P.heading:SetText(date('%A, %b %d, %Y',first))
    local events=M.Events(P.db,first,last,now,M.Day(now)==first,true,P.filter)
    if first==M.Day(now) then
        local ready={};local seconds=P.GetResetSeconds('daily')
        for _,e in ipairs(events) do
            if e.kind~='patron' or M.PatronDue(e.record,now,seconds) then ready[#ready+1]=e end
        end
        events=ready
    end
    local intro=P.Text('Log into each character and open both crafting professions once. /planner or /dmp opens this window.\nAll dates and AM/PM times use your computer local time.',4,0,P.width-8,'GameFontHighlightSmall')
    intro:SetWordWrap(true);intro:SetHeight(32)
    for i,e in ipairs(events) do P.EventRow(e,38+(i-1)*43) end
    if #events==0 then P.Empty(40) end
    P.content:SetHeight(math.max(62,38+#events*43))
end
function P.Weekly(now)
    local resetSeconds,fallback=P.ResetSeconds()
    local first,last=M.Week(now,resetSeconds,P.weekOffset)
    P.heading:SetText(date('%b %d',first)..' - '..date('%b %d, %Y',last))
    local events=M.Upcoming(P.db,M.Day(first),M.AddDays(M.Day(last),1),now,P.filter)
    local y=0
    P.Text('Upcoming this week | Reset-day sections start '..M.Clock(first)..' local.'..(fallback and ' (NA fallback)' or ''),4,-y,P.width,'GameFontHighlightSmall');y=y+22
    for d=0,6 do
        local a,b=first+d*86400,first+(d+1)*86400
        P.Text(date('%A, %b %d',a),4,-y,P.width,'GameFontNormal');y=y+22
        local count=0
        for _,e in ipairs(events) do
            local match=(e.kind=='patron' or e.kind=='note') and M.Key(e.at)==M.Key(a) or (e.kind=='concentration' and e.at>=a and e.at<b)
            if match and not e.ready and not (P.weekOffset==0 and e.overdue) then P.EventRow(e,y);y=y+43;count=count+1 end
        end
        if count==0 then P.Text('Nothing scheduled',8,-y,P.width-16,'GameFontDisableSmall');y=y+18 end
        y=y+4
    end
    P.content:SetHeight(math.max(24,y))
end
function P.Monthly(now)
    local d=date('*t',P.month or now)
    local first=time({year=d.year,month=d.month,day=1,hour=0,min=0,sec=0})
    local last=time({year=d.year,month=d.month+1,day=1,hour=0,min=0,sec=0})
    P.heading:SetText(date('%B %Y',first))
    local events=M.Events(P.db,first,last,now,false,false,P.filter)
    local buckets={}
    for _,e in ipairs(events) do local k=M.Key(e.at);buckets[k]=buckets[k] or {};table.insert(buckets[k],e) end
    local start=M.AddDays(first,-(date('*t',first).wday-1))
    local step=P.width/7;local cellWidth=step-2;local cellHeight=92
    for i,name in ipairs({'Sun','Mon','Tue','Wed','Thu','Fri','Sat'}) do P.Text(name,(i-1)*step,-1,cellWidth,'GameFontNormalSmall') end
    local rows=math.ceil((date('*t',first).wday-1+date('*t',M.AddDays(last,-1)).day)/7)
    for i=0,rows*7-1 do
        local day=M.AddDays(start,i);local dayInfo=date('*t',day)
        local cell=P.Widget(panel(P.content));cell:SetSize(cellWidth,cellHeight);cell:SetPoint('TOPLEFT',(i%7)*step,-21-math.floor(i/7)*(cellHeight+2))
        local inMonth=dayInfo.month==d.month;if not inMonth then cell:SetAlpha(.4) end
        if M.Key(day)==M.Key(now) then cell:SetBackdropBorderColor(unpack(purple)) end
        label(cell,tostring(dayInfo.day),4,-3,cellWidth-8,'GameFontNormalSmall')
        local list=inMonth and (buckets[M.Key(day)] or {}) or {}
        for j=1,math.min(2,#list) do
            local e=list[j];local text
            if e.kind=='note' then text='Note: '..plain(e.record.text)
            else text=e.character..'\n'..e.record.name..' '..M.Clock(e.at) end
            local l=label(cell,text,4,-20-(j-1)*29,cellWidth-8,'GameFontHighlightSmall');l:SetHeight(27);l:SetWordWrap(false)
        end
        if #list>2 then label(cell,'+'..(#list-2)..' more',4,-77,cellWidth-8,'GameFontNormalSmall') end
        cell:SetScript('OnMouseUp',function(_,mouse) if mouse=='LeftButton' then P.followToday=false;P.selectedDay=day;P.Show('daily') end end)
        local lines={}
        for _,e in ipairs(list) do lines[#lines+1]=e.kind=='note' and plain(e.record.text)..' ('..description(e)..')' or e.character..' '..profession(e.record)..' '..M.Clock(e.at) end
        if #lines==0 then lines[1]='No upcoming caps or reminders.' end
        lines[#lines+1]='Click for the daily planner and patron reminders.'
        tooltip(cell,date('%A, %B %d',day),lines)
    end
    P.content:SetHeight(22+rows*(cellHeight+2))
end
function P.Compact(now)
    local c=P.Character();local y=0
    if c then
        local name=P.Text(c.name..'-'..c.realm,6,-3,P.width-12,'GameFontNormal')
        name:SetWordWrap(false)
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[c.class]
        if color then name:SetTextColor(color.r,color.g,color.b) end
        y=25
        local professions={}
        for id,r in pairs(c.professions) do
            if M.Visible(P.db,r,id) then professions[#professions+1]={id=id,r=r} end
        end
        table.sort(professions,function(a,b) if a.r.name~=b.r.name then return a.r.name<b.r.name end;return a.id<b.id end)
        local seconds=P.GetResetSeconds('daily')
        local function stamp(at) return date('%b %d',at)..', '..M.Clock(at) end
        for _,v in ipairs(professions) do
            local r=v.r;local full=M.FullAt(r)
            local concentration=not full and 'Open profession to refresh' or (full<=now and 'Full now' or stamp(full))
            local patrons='Not scheduled'
            if r.patron then
                local at=M.PatronResetAt(r.patron.due,now,seconds)
                if M.PatronDue(r,now,seconds) then
                    patrons=(M.Day(r.patron.due)<M.Day(now) and 'Overdue: ' or 'Due: ')..(at and stamp(at) or M.Key(r.patron.due))
                else
                    patrons=at and stamp(at) or (M.Key(r.patron.due)..' (reset unavailable)')
                end
            end
            local row=P.Widget(panel(P.content));row:SetSize(P.width,74);row:SetPoint('TOPLEFT',0,-y)
            label(row,r.name,6,-6,P.width-122):SetWordWrap(false)
            local b=button(row,r.name..' Done',P.width-112,-3,106,function() M.CompletePatron(r,GetServerTime());P.Render(true) end)
            b:SetHeight(21)
            label(row,'Concentration: '..concentration,6,-29,P.width-12,'GameFontHighlightSmall'):SetWordWrap(false)
            label(row,'Patrons: '..patrons,6,-49,P.width-12,'GameFontHighlightSmall'):SetWordWrap(false)
            tooltip(row,profession(r),{'Concentration: '..concentration,'Patrons: '..patrons,'All dates and times are local. Patron reminders start after daily reset.'})
            tooltip(b,profession(r)..' patron orders',{'Next check: '..patrons,'Click Done to mark orders complete. Without a schedule, this starts the default four-day rotation.','You may mark orders done early.'})
            y=y+77
        end
        if #professions==0 then
            local text=P.Text('Open your crafting professions to collect data. Check prior-expansion visibility in Settings if needed.',6,-y,P.width-12,'GameFontHighlightSmall')
            text:SetWordWrap(true);text:SetHeight(40);y=y+43
        end
    end
    P.content:SetHeight(math.max(24,y))
    if not P.db.settings.compactSize and not P.resizing then
        local height=math.min(420,UIParent:GetHeight()-20,math.max(110,y+83))
        P.layoutLock=true;P.frame:SetHeight(height);P.layoutLock=false;P.Layout()
    end
end
function P.ScheduleEditor(r,character)
    local f=P.editor
    local names={'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'}
    if not f then
        f=panel(UIParent,'DuckMooPlannerPatronEditor');P.editor=f;table.insert(UISpecialFrames,'DuckMooPlannerPatronEditor');f:SetSize(460,265);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG')
        label(f,'Patron schedule',16,-14,410,'GameFontNormalLarge')
        f.caption=label(f,'',16,-43,420)
        f.modeText=function() f.modeButton:SetText(f.mode=='four' and 'Every 4 days after Done' or 'Every '..names[f.weekday]) end
        f.modeButton=button(f,'',16,-89,280,function() f.mode=f.mode=='four' and 'weekly' or 'four';f.modeText() end)
        button(f,'Next weekday',305,-89,135,function() f.mode='weekly';f.weekday=f.weekday%7+1;f.modeText() end)
        label(f,'First due date (YYYY-MM-DD)',16,-124,310)
        f.edit=CreateFrame('EditBox',nil,f,'InputBoxTemplate');f.edit:SetSize(160,24);f.edit:SetPoint('TOPLEFT',23,-147);f.edit:SetAutoFocus(false)
        f.edit:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        f.errorText=label(f,'',16,-177,420,'GameFontHighlightSmall')
        f.save=button(f,'Save',16,-218,100,function()
            local due=M.ParseDay(f.edit:GetText())
            if not due then f.errorText:SetText('Enter a real date, for example 2026-10-01.');return end
            if f.mode=='weekly' then due=M.NextWeekday(due,f.weekday) end
            M.SetSchedule(f.record,f.mode,due,f.weekday);f.edit:ClearFocus();f:Hide();P.Render()
        end)
        button(f,'Remove',126,-218,100,function() f.record.patron=nil;f:Hide();P.Render() end)
        button(f,'Cancel',336,-218,100,function() f:Hide() end)
    end
    f.record=r;f.mode=(r.patron and r.patron.mode) or 'four';f.weekday=(r.patron and r.patron.weekday) or 1
    f.caption:SetText(character..'\n'..profession(r));f.edit:SetText(M.Key((r.patron and r.patron.due) or GetServerTime()))
    f.errorText:SetText('');f.modeText();f:Show()
end
function P.Checkbox(text,x,y,width,checked,onClick)
    local check=P.Widget(acquire(P.content,'CheckButton','UICheckButtonTemplate'))
    check:SetSize(26,26);check:SetPoint('TOPLEFT',x,-y);check:SetChecked(checked)
    local caption=label(check,text,30,-5,width-30,'GameFontHighlightSmall');caption:SetWordWrap(false)
    check:SetScript('OnClick',function(self) onClick(self:GetChecked()) end)
    return check
end
function P.ForgetProfession(v)
    if not StaticPopupDialogs.DUCKMOOPLANNER_FORGET then
        StaticPopupDialogs.DUCKMOOPLANNER_FORGET={text='Forget %s from DuckMoo Planner? This removes its snapshot and patron schedule.',button1='Forget',button2='Cancel',timeout=0,whileDead=true,hideOnEscape=true,
            OnAccept=function(_,data)
                local c=P.db.characters[data.guid];if c then c.professions[data.id]=nil end
                P.Render(true)
            end}
    end
    StaticPopup_Show('DUCKMOOPLANNER_FORGET',v.name..' '..profession(v.r),nil,{guid=v.guid,id=v.id})
end
function P.RosterRow(v,y)
    local r,w=v.r,P.width
    local row=P.Widget(panel(P.content));row:SetSize(w,61);row:SetPoint('TOPLEFT',0,-y)
    local title=label(row,v.name..'  |  '..profession(r),8,-5,w-16);title:SetWordWrap(false)
    local s=r.patron;local full=M.FullAt(r);local summary
    if full then summary=full<=GetServerTime() and 'FULL' or 'Full '..date('%b %d',full)..' '..M.Clock(full) else summary='Waiting for data' end
    if s then summary=summary..' | Patrons '..(s.mode=='four' and '4 days' or 'weekly')..' | '..M.Key(s.due) end
    label(row,summary,8,-24,w-16,'GameFontHighlightSmall'):SetWordWrap(false)
    button(row,'Patron schedule',8,-39,130,function() P.ScheduleEditor(r,v.name) end):SetHeight(20)
    button(row,r.hidden and 'Unhide' or 'Hide',144,-39,66,function() r.hidden=not r.hidden;P.Render(true) end):SetHeight(20)
    button(row,'Forget',216,-39,72,function() P.ForgetProfession(v) end):SetHeight(20)
    tooltip(row,v.name..' '..profession(r),{summary,r.hidden and 'Hidden from planner views.' or 'Included when this expansion is enabled.'})
end
function P.Settings(now)
    P.heading:SetText('Settings')
    for i,v in ipairs({'roster','appearance','about'}) do
        local tab=v
        local b=P.Widget(button(P.content,v:sub(1,1):upper()..v:sub(2),4+(i-1)*120,0,114,function() P.settingsTab=tab;P.rosterPage=1;P.Render() end))
        b:SetBackdropBorderColor(.75,.48,.95,P.settingsTab==v and 1 or 0)
    end
    if P.settingsTab=='appearance' then P.Appearance(now)
    elseif P.settingsTab=='about' then P.About(now)
    else P.RosterSettings(now) end
end
local noteModeNames={once='Once',dailyReset='After daily reset',weeklyReset='After weekly reset',days='Every X days after dismissal'}
function P.NoteEditor(n)
    local f=P.noteEditor
    if not f then
        f=panel(UIParent,'DuckMooPlannerNoteEditor');P.noteEditor=f;f:SetSize(480,320);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
        table.insert(UISpecialFrames,'DuckMooPlannerNoteEditor')
        label(f,'Custom reminder',14,-13,440,'GameFontNormalLarge')
        label(f,'Note (up to 500 characters)',14,-44,440,'GameFontHighlightSmall')
        f.text=editBox(f,21,-66,438);f.text:SetMaxLetters(500)
        label(f,'First date (YYYY-MM-DD)',14,-103,440,'GameFontHighlightSmall')
        f.date=editBox(f,21,-123,180);f.date:SetMaxLetters(10)
        f.modeButton=button(f,'',14,-158,446,function()
            local modes={'once','dailyReset','weeklyReset','days'}
            for i,m in ipairs(modes) do if m==f.mode then f.mode=modes[i%#modes+1];break end end
            f.updateMode()
        end)
        f.updateMode=function()
            f.modeButton:SetText('Repeat: '..noteModeNames[f.mode]..' (click to change)')
            f.interval:SetShown(f.mode=='days');f.intervalLabel:SetShown(f.mode=='days')
        end
        f.intervalLabel=label(f,'Number of days',14,-195,260,'GameFontHighlightSmall')
        f.interval=editBox(f,290,-189,168);f.interval:SetMaxLetters(4)
        f.errorText=label(f,'',14,-224,446,'GameFontHighlightSmall');f.errorText:SetHeight(42)
        f.save=button(f,'Save & schedule',14,-278,146,function()
            local saved,err=P.SaveNote(f.record,f.text:GetText(),f.date:GetText(),f.mode,f.interval:GetText())
            if not saved then f.errorText:SetText(err);return end
            f.text:ClearFocus();f.date:ClearFocus();f.interval:ClearFocus();f:Hide();P.Render(true)
        end)
        button(f,'Cancel',362,-278,98,function() f:Hide() end)
    end
    f.record=n;f.mode=n and n.mode or 'once'
    f.text:SetText(n and n.text or '')
    f.date:SetText(M.Key(n and n.due or (P.db.settings.compact and GetServerTime() or P.selectedDay or GetServerTime())))
    f.interval:SetText(tostring(n and n.interval or 4));f.errorText:SetText('');f.updateMode();f:Show()
end
function P.DeleteNote(n)
    if not StaticPopupDialogs.DUCKMOOPLANNER_DELETE_NOTE then
        StaticPopupDialogs.DUCKMOOPLANNER_DELETE_NOTE={text='Delete this custom reminder?\n%s',button1='Delete',button2='Cancel',timeout=0,whileDead=true,hideOnEscape=true,
            OnAccept=function(_,id) P.db.notes[id]=nil;P.Render(true) end}
    end
    StaticPopup_Show('DUCKMOOPLANNER_DELETE_NOTE',plain(n.text),nil,n.id)
end
function P.Reminders(now)
    P.heading:SetText('Custom reminders')
    local notes={}
    for _,n in pairs(P.db.notes) do if n.text:lower():find(P.filter:lower(),1,true) then notes[#notes+1]=n end end
    table.sort(notes,function(a,b)
        if (a.dismissedAt~=nil)~=(b.dismissedAt~=nil) then return a.dismissedAt==nil end
        if a.due~=b.due then return a.due<b.due end
        return a.id<b.id
    end)
    for i,n in ipairs(notes) do
        local w=P.width;local row=P.Widget(panel(P.content));row:SetSize(w,48);row:SetPoint('TOPLEFT',0,-(i-1)*51)
        label(row,plain(n.text),8,-5,w-220):SetWordWrap(false)
        local summary=n.dismissedAt and 'Dismissed' or ('Due '..M.Key(n.due)..' | '..(noteModeNames[n.mode] or 'Once'))
        if n.mode=='days' then summary=summary..' ('..n.interval..')' end
        label(row,summary,8,-27,w-16,'GameFontHighlightSmall'):SetWordWrap(false)
        button(row,n.dismissedAt and 'Restore' or 'Dismiss',w-212,-3,76,function()
            if n.dismissedAt then n.dismissedAt=nil;P.Render(true) else P.DismissNote(n) end
        end)
        button(row,'Edit',w-130,-3,54,function() P.NoteEditor(n) end)
        button(row,'Delete',w-70,-3,64,function() P.DeleteNote(n) end)
        tooltip(row,plain(n.text),{summary,'Repeat intervals restart when dismissed. Unfinished reminders remain visible.','Saving edits schedules the reminder again.'})
    end
    if #notes==0 then P.Text('Click + Note to add a dated or repeating reminder.',8,-4,P.width-16,'GameFontHighlightSmall') end
    P.content:SetHeight(math.max(24,#notes*51))
end
function P.Render(preserveScroll)
    if not P.frame or not P.db then return end
    local scroll=preserveScroll and P.scroll:GetVerticalScroll() or 0
    P.Layout();P.Clear()
    local now=GetServerTime();P.lastRenderedDay=M.Key(now)
    P.dynamic=true
    if P.followToday then P.selectedDay=M.Day(now) end
    P.db.settings.fullView=P.view;P.db.settings.view=P.view
    if P.db.settings.compact then P.Compact(now)
    elseif P.view=='monthly' then P.Monthly(now)
    elseif P.view=='weekly' then P.Weekly(now)
    elseif P.view=='settings' then P.Settings(now)
    elseif P.view=='reminders' then P.Reminders(now)
    else P.Daily(now) end
    P.dynamic=false
    P.UpdateCountdown()
    P.scroll:SetVerticalScroll(math.min(scroll,math.max(0,P.content:GetHeight()-P.scroll:GetHeight())))
end

-- One reusable, scrollable chooser instead of cycling through hundreds of names.
function P.Choose(title,options,onSelect)
    local f=P.choice
    if not f then
        f=panel(UIParent,'DuckMooPlannerChooser');P.choice=f;f:SetSize(330,335);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG')
        table.insert(UISpecialFrames,'DuckMooPlannerChooser')
        f.title=label(f,'',12,-12,300,'GameFontNormal')
        f.search=editBox(f,19,-38,290)
        f.scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');f.scroll:SetPoint('TOPLEFT',12,-69);f.scroll:SetSize(285,225)
        f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetSize(285,1);f.scroll:SetScrollChild(f.content);f.buttons={}
        button(f,'Cancel',220,-302,98,function() f:Hide() end)
        f.draw=function()
            for _,b in ipairs(f.buttons) do b:Hide() end
            local term=f.search:GetText():lower();local i=0
            for _,option in ipairs(f.options or {}) do
                if option.label:lower():find(term,1,true) then
                    i=i+1;local b=f.buttons[i]
                    if not b then b=button(f.content,'',0,0,282,function() end);f.buttons[i]=b end
                    b:ClearAllPoints();b:SetPoint('TOPLEFT',0,-(i-1)*26);b:SetText(plain(option.label));b:Show()
                    b:SetScript('OnClick',function() local callback=f.callback;f:Hide();callback(option.value) end)
                end
            end
            f.content:SetHeight(math.max(1,i*26));f.scroll:SetVerticalScroll(0)
        end
        f.search:SetScript('OnTextChanged',function() f.draw() end)
    end
    f.options=options;f.callback=onSelect;f.title:SetText(title);f.search:SetText('');f.draw();f:Show()
end
function P.OpacityControl(key,title,y)
    local s=P.db.settings
    local caption=P.Text(title..': '..math.floor(s[key]*100+.5)..'%',4,-y,235,'GameFontHighlightSmall')
    local slider=P.Widget(acquire(P.content,'Slider','BackdropTemplate'))
    slider:SetSize(math.min(280,P.width-250),17);slider:SetPoint('TOPLEFT',245,-y);slider:SetOrientation('HORIZONTAL')
    slider:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8'});slider:SetBackdropColor(.16,.10,.22,1)
    slider:SetThumbTexture('Interface/Buttons/UI-SliderBar-Button-Horizontal');slider:SetMinMaxValues(20,100);slider:SetValueStep(5);slider:SetObeyStepOnDrag(true)
    slider:SetScript('OnValueChanged',nil);slider:SetValue(s[key]*100)
    slider:SetScript('OnValueChanged',function(_,value)
        s[key]=math.max(.2,math.min(1,value/100));caption:SetText(title..': '..math.floor(s[key]*100+.5)..'%')
        P.frame:SetAlpha(s.compact and s.compactAlpha or s.fullAlpha)
    end)
    return slider
end
function P.Appearance(now)
    local s=P.db.settings
    P.Checkbox('Open the last view / mode at login',0,35,P.width,s.login,function(v) s.login=v end)
    P.Checkbox('Show the minimap button',0,67,P.width,not s.hideMinimap,function(v) s.hideMinimap=not v;P.CreateMinimap() end)
    P.fullOpacitySlider=P.OpacityControl('fullAlpha','Full window opacity',108)
    P.opacitySlider=P.OpacityControl('compactAlpha','Compact window opacity',146)
    P.Text('Glass for the planner, breathing room for Azeroth. Defaults: full 85%, compact 65%.',4,-182,P.width-8,'GameFontHighlightSmall')
    P.Text('Resize each mode from its bottom-right corner. Sizes and positions are remembered separately.',4,-207,P.width-8,'GameFontHighlightSmall')
    P.content:SetHeight(235)
end
function P.GroupEditor(guids)
    local f=P.groupEditor
    if not f then
        f=panel(UIParent,'DuckMooPlannerGroups');P.groupEditor=f;f:SetSize(490,350);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG')
        table.insert(UISpecialFrames,'DuckMooPlannerGroups')
        f.title=label(f,'Groups',12,-12,460,'GameFontNormalLarge')
        f.edit=editBox(f,19,-42,280);f.edit:SetMaxLetters(60)
        f.save=button(f,'Create group',312,-42,160,function()
            local id,err=P.SaveGroup(f.editID,f.edit:GetText())
            if not id then f.error:SetText(err);return end
            if not f.editID then M.AssignGroup(P.db,f.guids,id,true) end
            f.editID=nil;f.edit:SetText('');f.save:SetText('Create group');f.error:SetText('');f.draw();P.Render(true)
        end)
        f.error=label(f,'Check to assign; uncheck to remove. Characters can belong to several groups.',12,-75,456,'GameFontHighlightSmall');f.error:SetHeight(30)
        f.scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');f.scroll:SetPoint('TOPLEFT',12,-110);f.scroll:SetSize(444,192)
        f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetSize(444,1);f.scroll:SetScrollChild(f.content);f.rows={}
        button(f,'Done',372,-315,100,function() f:Hide();P.Render(true) end)
        button(f,'New group',12,-315,110,function() f.editID=nil;f.edit:SetText('');f.save:SetText('Create group') end)
        f.draw=function()
            for _,row in ipairs(f.rows) do row:Hide() end
            local groups={}
            for id,g in pairs(P.db.groups) do groups[#groups+1]={id=id,name=g.name} end
            table.sort(groups,function(a,b) return a.name<b.name end)
            for i,g in ipairs(groups) do
                local row=f.rows[i]
                if not row then
                    row=panel(f.content);row:SetSize(440,31)
                    row.check=CreateFrame('CheckButton',nil,row,'UICheckButtonTemplate');row.check:SetSize(25,25);row.check:SetPoint('TOPLEFT',1,-3)
                    row.caption=label(row,'',30,-8,244,'GameFontHighlightSmall')
                    row.rename=button(row,'Rename',284,-4,75,function() end);row.delete=button(row,'Delete',365,-4,68,function() end)
                    f.rows[i]=row
                end
                row:ClearAllPoints();row:SetPoint('TOPLEFT',0,-(i-1)*34);row.caption:SetText(plain(g.name));row.caption:SetWordWrap(false);row:Show()
                local all=true
                for _,guid in ipairs(f.guids) do local c=P.db.characters[guid];if not c or not c.groups or not c.groups[g.id] then all=false end end
                row.check:SetChecked(all)
                row.check:SetScript('OnClick',function(self) M.AssignGroup(P.db,f.guids,g.id,self:GetChecked());P.Render(true) end)
                row.rename:SetScript('OnClick',function() f.editID=g.id;f.edit:SetText(g.name);f.save:SetText('Save name') end)
                row.delete:SetScript('OnClick',function()
                    if not StaticPopupDialogs.DUCKMOOPLANNER_DELETE_GROUP then
                        StaticPopupDialogs.DUCKMOOPLANNER_DELETE_GROUP={text='Delete group %s? Characters and profession schedules stay intact.',button1='Delete',button2='Cancel',timeout=0,whileDead=true,hideOnEscape=true,
                            OnAccept=function(_,id) M.DeleteGroup(P.db,id);if P.db.settings.rosterGroup==id then P.db.settings.rosterGroup=nil end;f.draw();P.Render(true) end}
                    end
                    StaticPopup_Show('DUCKMOOPLANNER_DELETE_GROUP',plain(g.name),nil,g.id)
                end)
            end
            f.content:SetHeight(math.max(1,#groups*34))
        end
    end
    f.guids=guids;f.editID=nil;f.edit:SetText('');f.save:SetText('Create group');f.error:SetText('Check to assign; uncheck to remove. Characters can belong to several groups.')
    f.title:SetText('Groups | '..#guids..' selected character'..(#guids==1 and '' or 's'))
    f.draw();f:Show()
end
function P.CharacterRoster(e,y,pinned)
    local w=P.width
    local row=P.Widget(panel(P.content));local height=29+#e.professions*29
    row:SetSize(w,height);row:SetPoint('TOPLEFT',0,-y)
    if pinned then row:SetBackdropBorderColor(.71,.45,.95,1) end
    local offset=8
    if not pinned then
        local check=acquire(row,'CheckButton','UICheckButtonTemplate');check:SetSize(24,24);check:SetPoint('TOPLEFT',1,-2);check:SetChecked(P.selectedCharacters[e.guid])
        check:SetScript('OnClick',function(self)
            P.selectedCharacters[e.guid]=self:GetChecked() and true or nil
            local count=0;for _ in pairs(P.selectedCharacters) do count=count+1 end
            if P.bulkGroupButton then P.bulkGroupButton:SetText('Group selected ('..count..')') end
        end)
        offset=29
    end
    local title=label(row,(pinned and 'This character: ' or '')..e.name..' | '..e.realm,offset,-6,w-offset-150)
    title:SetWordWrap(false)
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.c.class];if color then title:SetTextColor(color.r,color.g,color.b) end
    local group=button(row,'Groups',w-82,-2,74,function() P.GroupEditor({e.guid}) end)
    tooltip(group,'Character groups',{e.groups~='' and e.groups or 'No groups assigned.','Create or assign multiple groups for this character.'})
    for i,v in ipairs(e.professions) do
        local r=v.r;local top=28+(i-1)*29
        local full=M.FullAt(r);local status=full and (full<=GetServerTime() and 'Full now' or date('%b %d',full)..' '..M.Clock(full)) or 'Waiting for data'
        local text=label(row,r.name..(M.IsMidnight(r,v.id) and '' or ' [prior]')..'  |  '..status,12,-top-4,w-295,'GameFontHighlightSmall');text:SetWordWrap(false)
        local schedule=r.patron and (r.patron.mode=='four' and '4-day' or 'Weekly') or 'Set schedule'
        local b=button(row,schedule,w-278,-top,110,function() P.ScheduleEditor(r,e.name..'-'..e.realm) end)
        tooltip(b,profession(r),{r.patron and ('Patrons due '..M.Key(r.patron.due)) or 'Choose a patron reminder schedule.','Compact Done creates a four-day schedule if none exists.'})
        button(row,r.hidden and 'Show' or 'Hide',w-161,-top,65,function() r.hidden=not r.hidden;P.Render(true) end)
        button(row,'Forget',w-89,-top,77,function() P.ForgetProfession(v) end)
    end
    if #e.professions==0 then tooltip(row,e.name,{'Open both crafting professions once to register this character.'}) end
    return height+5
end
function P.RosterSettings(now)
    local s=P.db.settings
    local current=UnitGUID('player')
    local pinned,roster=M.Roster(P.db,current,{prior=s.priorExpanded,profession=s.rosterProfession or nil,realm=s.rosterRealm or nil,group=s.rosterGroup or nil,
        sort=s.rosterSort,descending=s.rosterDescending,search=P.filter})
    P.currentRoster=pinned;P.filteredRoster=roster
    local y=35
    if pinned then y=y+P.CharacterRoster(pinned,y,true) end
    local filterY=y
    local function choice(key,title,options)
        P.Choose(title,options,function(value) s[key]=value;P.rosterPage=1;P.Render() end)
    end
    local function options(field)
        local list,seen={{label='All '..field,value=false}},{}
        for _,c in pairs(P.db.characters) do
            if field=='realms' then seen[c.realm]=true else for _,r in pairs(c.professions) do seen[r.name]=true end end
        end
        local sorted={};for name in pairs(seen) do sorted[#sorted+1]=name end;table.sort(sorted)
        for _,name in ipairs(sorted) do list[#list+1]={label=name,value=name} end
        return list
    end
    local groupName=s.rosterGroup=='ungrouped' and 'Ungrouped' or (s.rosterGroup and P.db.groups[s.rosterGroup] and P.db.groups[s.rosterGroup].name) or 'All groups'
    local col=(P.width-12)/3
    P.Widget(button(P.content,s.rosterProfession or 'All professions',4,-filterY,col-4,function() choice('rosterProfession','Filter profession',options('professions')) end))
    P.Widget(button(P.content,s.rosterRealm or 'All realms',8+col,-filterY,col-4,function() choice('rosterRealm','Filter realm',options('realms')) end))
    P.Widget(button(P.content,plain(groupName),12+col*2,-filterY,col-4,function()
        local list={{label='All groups',value=false},{label='Ungrouped',value='ungrouped'}}
        local sorted={};for id,g in pairs(P.db.groups) do sorted[#sorted+1]={label=g.name,value=id} end
        table.sort(sorted,function(a,b) return a.label<b.label end);for _,v in ipairs(sorted) do list[#list+1]=v end
        choice('rosterGroup','Filter group',list)
    end))
    P.Widget(button(P.content,'Sort: '..(s.rosterSort or 'name'),4,-filterY-30,136,function()
        choice('rosterSort','Sort roster',{{label='Character name',value='name'},{label='Realm',value='realm'},{label='Profession',value='profession'},{label='Group',value='group'}})
    end))
    P.Widget(button(P.content,s.rosterDescending and 'Descending' or 'Ascending',146,-filterY-30,105,function() s.rosterDescending=not s.rosterDescending;P.Render() end))
    P.bulkGroupButton=P.Widget(button(P.content,'Group selected',257,-filterY-30,135,function()
        local guids={};for guid in pairs(P.selectedCharacters) do if P.db.characters[guid] then guids[#guids+1]=guid end end
        if #guids==0 then P.Print('Select characters using the roster checkboxes first.');return end
        P.GroupEditor(guids)
    end))
    local selectedCount=0;for _ in pairs(P.selectedCharacters) do selectedCount=selectedCount+1 end
    P.bulkGroupButton:SetText('Group selected ('..selectedCount..')')
    P.Widget(button(P.content,'Clear selection',398,-filterY-30,135,function() P.selectedCharacters={};P.Render(true) end))
    y=filterY+62
    P.Widget(button(P.content,(s.priorExpanded and '[-] ' or '[+] ')..'Prior expansions',4,-y,170,function() s.priorExpanded=not s.priorExpanded;P.rosterPage=1;P.Render(true) end));y=y+28
    if s.priorExpanded then P.Checkbox('Include prior expansions in planner views',0,y,P.width,s.includePrior,function(v) s.includePrior=v;P.Render(true) end);y=y+30 end
    local pageSize=15;local pages=math.max(1,math.ceil(#roster/pageSize))
    P.rosterPage=math.min(pages,math.max(1,P.rosterPage));local page=P.rosterPage
    P.Text('Alt army | '..#roster..' characters | Page '..page..' / '..pages,4,-y,P.width-180,'GameFontNormal')
    P.Widget(button(P.content,'<',P.width-160,-y-2,45,function() P.rosterPage=math.max(1,page-1);P.Render() end))
    P.Widget(button(P.content,'>',P.width-110,-y-2,45,function() P.rosterPage=math.min(pages,page+1);P.Render() end))
    P.Widget(button(P.content,'Reset',P.width-60,-y-2,56,function() s.rosterProfession=nil;s.rosterRealm=nil;s.rosterGroup=nil;s.rosterSort='name';s.rosterDescending=false;P.filter='';P.search:SetText('');P.rosterPage=1;P.Render() end))
    y=y+30
    local first=(page-1)*pageSize+1
    for i=first,math.min(#roster,first+pageSize-1) do y=y+P.CharacterRoster(roster[i],y,false) end
    if #roster==0 then P.Text('No alts match. Register more characters or loosen the filters.',8,-y,P.width-16,'GameFontHighlightSmall');y=y+25 end
    P.content:SetHeight(math.max(24,y))
end
function P.CopyText(text)
    local f=P.copyDialog
    if not f then
        f=panel(UIParent,'DuckMooPlannerCopy');P.copyDialog=f;f:SetSize(480,125);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG')
        table.insert(UISpecialFrames,'DuckMooPlannerCopy')
        label(f,'Copy with Ctrl+C. Go forth and cause tasteful chaos.',12,-13,452,'GameFontHighlightSmall')
        f.edit=editBox(f,19,-43,440)
        button(f,'Done',366,-87,98,function() f:Hide() end)
    end
    f.edit:SetText(text);f:Show();f.edit:SetFocus();f.edit:HighlightText()
end
function P.About(now)
    local y=38
    local function paragraph(text,height,font)
        local l=P.Text(text,8,-y,P.width-16,font or 'GameFontHighlight');l:SetWordWrap(true);l:SetHeight(height);y=y+height+10
    end
    paragraph(P.fullName,27,'GameFontNormalLarge')
    paragraph('By DuckMoo Media | v'..P.version..' | Another suspiciously useful thing by DuckMoo Media.',30,'GameFontHighlightSmall')
    paragraph('Your alt army has Concentration. You have approximately twelve browser tabs open in your brain. This is mission control for the crafting gremlins: recharge forecasts, patron reminders, a calendar, and a compact dashboard for the character you are on.',68)
    paragraph('Deploy the ducks: log into each character and open both crafting professions once. Use /planner or /dmp, or click the minimap duck. Daily catches full bars and today\'s work. Weekly looks ahead. Monthly puts future caps on actual dates. Compact keeps the marching orders small.',68)
    paragraph('Wrangle the horde in Settings > Roster: pin your current character, filter by profession or realm, sort the alt army, and make your own groups. Check several characters and use Group selected to assign them together. Prior expansions stay tucked away until invited.',68)
    paragraph('Patron Done starts a four-day schedule if you have not set one. Configure a weekday if that suits your routine better. Add custom notes for all the side quests your actual brain refuses to keep in RAM.',54)
    paragraph('All dates and AM/PM times use your computer local time. Offline Concentration is an estimate from the last observed snapshot. Visit each character to refresh it. This planner does not craft, submit orders, or switch characters for you. The gremlins still need a pilot.',68,'GameFontHighlightSmall')
    paragraph('Find the DuckMoo universe',23,'GameFontNormal')
    paragraph('Books: amazon.com/author/kenzieduckmoo',28,'GameFontHighlightSmall')
    P.Widget(button(P.content,'Copy Amazon page',8,-y,170,function() P.CopyText('amazon.com/author/kenzieduckmoo') end));y=y+34
    paragraph('Twitch, AO3, Threads, Instagram, TikTok and YouTube: @KenzieDuckMoo\nBlueSky: @kenzieduckmoo.bsky.social',48,'GameFontHighlightSmall')
    P.Widget(button(P.content,'Copy creator handle',8,-y,170,function() P.CopyText('@KenzieDuckMoo') end))
    P.Widget(button(P.content,'Copy BlueSky handle',186,-y,176,function() P.CopyText('@kenzieduckmoo.bsky.social') end));y=y+36
    paragraph('DuckMoo Media: making the chaos legible, one aggressively organized duck at a time. Please hydrate before logging into your 94th alchemist.',40,'GameFontHighlightSmall')
    P.content:SetHeight(y)
end
