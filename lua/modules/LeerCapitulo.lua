----------------------------------------------------------------------------------------------------
-- Module Initialization
----------------------------------------------------------------------------------------------------

function Init()
	local m = NewWebsiteModule()
	m.ID                       = 'c67d163c51b24bc498e777e2b0d810d2'
	m.Name                     = 'LeerCapitulo'
	m.RootURL                  = 'https://www.leercapitulo.co'
	m.Category                 = 'Spanish'
	m.OnGetNameAndLink         = 'GetNameAndLink'
	m.OnGetInfo                = 'GetInfo'
	m.OnGetPageNumber          = 'GetPageNumber'
end

----------------------------------------------------------------------------------------------------
-- Local Constants
----------------------------------------------------------------------------------------------------

local DirectoryPagination = '/manga/'

----------------------------------------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------------------------------------

-- Checks that an element has the class c. contains(@class, 'n') alone would
-- also match any other class with an "n" in it.
local function HasClass(c)
	return 'contains(concat(" ", normalize-space(@class), " "), " ' .. c .. ' ")'
end

----------------------------------------------------------------------------------------------------
-- Event Functions
----------------------------------------------------------------------------------------------------

-- Get links and names from the manga list of the current website.
function GetNameAndLink()
	local u = MODULE.RootURL .. DirectoryPagination .. '?page=' .. (URL + 1)

	if not HTTP.GET(u) then return net_problem end

	local x = CreateTXQuery(HTTP.Document)
	x.XPathHREFAll('//a[contains(@class, "lc-card-name")]', LINKS, NAMES)
	UPDATELIST.CurrentDirectoryPageNumber = tonumber(x.XPathString('(//*[contains(@class, "page-link")][number(.) = number(.)])[last()]')) or 1

	return no_error
end

-- Get info and chapter list for the current manga.
function GetInfo()
	local u = MaybeFillHost(MODULE.RootURL, URL)

	if not HTTP.GET(u) then return net_problem end

	local x = CreateTXQuery(HTTP.Document)
	-- The box with the cover and the series details. Reading only from it
	-- avoids picking up other series listed in the sidebar.
	local panel = '//article[.//div[contains(@class, "lc-cover-lg")]]'
	local fact = function(label)
		return x.XPathString(panel .. '//ul[contains(@class, "lc-facts")]//span[' .. HasClass('k') .. '][.="' .. label .. '"]/following-sibling::*[1]')
	end
	MANGAINFO.Title     = x.XPathString(panel .. '//h1')
	MANGAINFO.AltTitles = (x.XPathString(panel .. '//h1/following-sibling::p[contains(@class, "lc-muted")][1]'):gsub(' · ', ', '))
	MANGAINFO.CoverLink = MaybeFillHost(MODULE.RootURL, x.XPathString(panel .. '//div[contains(@class, "lc-cover-lg")]/img/@src'))
	MANGAINFO.Authors   = fact('Autor')
	MANGAINFO.Genres    = x.XPathStringAll(panel .. '//a[contains(@href, "?genre=") or contains(@href, "?theme=")]')
	MANGAINFO.Status    = MangaInfoStatusIfPos(fact('Estado'), 'Ongoing', 'Completed', 'Paused', 'Cancelled')
	MANGAINFO.Summary   = x.XPathString('//section[@id="sinopsis"]//p')

	for v in x.XPath('//a[contains(@class, "lc-chapter-row")]').Get() do
		MANGAINFO.ChapterLinks.Add(v.GetAttribute('href'))
		MANGAINFO.ChapterNames.Add(x.XPathString('span[' .. HasClass('n') .. ']', v))
	end
	MANGAINFO.ChapterLinks.Reverse(); MANGAINFO.ChapterNames.Reverse()

	return no_error
end

-- Get the page count and/or page links for the current chapter.
function GetPageNumber()
	local u = MaybeFillHost(MODULE.RootURL, URL)

	if not HTTP.GET(u) then return false end

	CreateTXQuery(HTTP.Document).XPathStringAll('//*[@id="lcPages"]//img/@data-src', TASK.PageLinks)

	return true
end