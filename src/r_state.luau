--!native
--!optimize 2
local r_state = {}

-- ---------------------------------------------------------------------------
-- Renderer constants (r_main.h / r_plane.h / r_things.h / r_sky.h)
-- ---------------------------------------------------------------------------

r_state.LIGHTLEVELS = 16
r_state.LIGHTSEGSHIFT = 4
r_state.MAXLIGHTSCALE = 48
r_state.LIGHTSCALESHIFT = 12
r_state.MAXLIGHTZ = 128
r_state.LIGHTZSHIFT = 20
r_state.NUMCOLORMAPS = 32

r_state.MAXDRAWSEGS = 256
r_state.MAXVISSPRITES = 128
r_state.MAXVISPLANES = 128
r_state.MAXOPENINGS = 320 * 64
r_state.MAXSEGS = 32

r_state.SBARHEIGHT = 32
r_state.FIELDOFVIEW = 2048

r_state.ANGLETOSKYSHIFT = 22

-- Silhouette constants (r_defs.h).
r_state.SIL_NONE = 0
r_state.SIL_BOTTOM = 1
r_state.SIL_TOP = 2
r_state.SIL_BOTH = 3

-- Frame flags (p_pspr.h).
r_state.FF_FULLBRIGHT = 0x8000
r_state.FF_FRAMEMASK = 0x7fff

-- Sprite flags (p_mobj.h) used by the renderer.
r_state.MF_SHADOW = 0x40000
r_state.MF_TRANSLATION = 0xc000000
r_state.MF_TRANSSHIFT = 26

-- ML_* line flags used by the renderer (doomdata.h).
r_state.ML_DONTPEGBOTTOM = 16
r_state.ML_DONTPEGTOP = 8
r_state.ML_TWOSIDED = 4
r_state.ML_MAPPED = 256

-- ---------------------------------------------------------------------------
-- Map data (p_setup / r_state.h lookup tables).
-- ---------------------------------------------------------------------------

r_state.numvertexes = 0
r_state.vertexes = {}

r_state.numsegs = 0
r_state.segs = {}

r_state.numsectors = 0
r_state.sectors = {}

r_state.numsubsectors = 0
r_state.subsectors = {}

r_state.numnodes = 0
r_state.nodes = {}

r_state.numlines = 0
r_state.lines = {}

r_state.numsides = 0
r_state.sides = {}

-- ---------------------------------------------------------------------------
-- Blockmap / reject (p_local.h, loaded by p_setup). These are playstate
-- globals but live here alongside the other map data so p_* modules can
-- share them without C-style header coupling / require cycles.
-- ---------------------------------------------------------------------------

r_state.bmapwidth = 0
r_state.bmapheight = 0 -- size in mapblocks
r_state.blockmaplump = {} -- array of swapped shorts (C short*); offsets are from here
r_state.blockmap = 4 -- offset into blockmaplump of the first block list (C blockmaplump+4)
r_state.bmaporgx = 0
r_state.bmaporgy = 0 -- origin of block map
r_state.blocklinks = {} -- blocklinks[y*bmapwidth+x] = head mobj of the block

-- REJECT: for fast sight rejection. A { buffer, offset, size } view (either
-- into the WAD lump, or a padded Z_Malloc'd buffer when the lump is small).
r_state.rejectmatrix = nil

-- ---------------------------------------------------------------------------
-- Renderer data (r_data.h / r_state.h).
-- ---------------------------------------------------------------------------

-- Textures: textures[tex] = { name, width, height, index, next, patchcount,
-- patches = { { originx, originy, patch } } }.
r_state.numtextures = 0
r_state.textures = {}
r_state.textures_hashtable = nil

r_state.texturewidthmask = {}
r_state.textureheight = {}
r_state.texturecompositesize = {}
r_state.texturecolumnlump = {}
r_state.texturecolumnofs = {}
r_state.texturecomposite = {}

-- Flats.
r_state.firstflat = 0
r_state.lastflat = 0
r_state.numflats = 0
r_state.flattranslation = {}

-- Sprites.
r_state.firstspritelump = 0
r_state.lastspritelump = 0
r_state.numspritelumps = 0
r_state.spritewidth = {}
r_state.spriteoffset = {}
r_state.spritetopoffset = {}

r_state.numsprites = 0
r_state.sprites = {}

r_state.colormaps = nil -- { buffer, offset, size } view of the COLORMAP lump

-- Texture translation (global animation).
r_state.texturetranslation = {}

-- Sky.
r_state.skyflatnum = 0
r_state.skytexture = 0
r_state.skytexturemid = 0

-- ---------------------------------------------------------------------------
-- POV / view globals (r_main.h / r_state.h).
-- ---------------------------------------------------------------------------

r_state.viewx = 0
r_state.viewy = 0
r_state.viewz = 0
r_state.viewangle = 0
r_state.viewplayer = nil
r_state.viewcos = 0
r_state.viewsin = 0
r_state.viewangleoffset = 0

r_state.centerx = 0
r_state.centery = 0
r_state.centerxfrac = 0
r_state.centeryfrac = 0
r_state.projection = 0

r_state.validcount = 1

r_state.framecount = 0
r_state.sscount = 0
r_state.linecount = 0
r_state.loopcount = 0

r_state.detailshift = 0

-- View size.
r_state.viewwidth = 0
r_state.scaledviewwidth = 0
r_state.viewheight = 0
r_state.viewwindowx = 0
r_state.viewwindowy = 0

r_state.clipangle = 0
r_state.viewangletox = {}
r_state.xtoviewangle = {}

-- Preallocate the fixed-size LUT arrays (the C uses static arrays that are
-- zero-initialized; Lua tables need explicit slots to avoid nil reads).
do
    local function fill(n)
        local t = {}
        for _ = 1, n do
            table.insert(t, 0)
        end
        return t
    end
    r_state.viewangletox = fill(4096)   -- FINEANGLES/2
    r_state.xtoviewangle = fill(321)    -- SCREENWIDTH+1
    r_state.scalelightfixed = fill(48)  -- MAXLIGHTSCALE
    r_state.floorclip = fill(320)
    r_state.ceilingclip = fill(320)
    r_state.spanstart = fill(200)
    r_state.spanstop = fill(200)
    r_state.yslope = fill(200)
    r_state.distscale = fill(320)
    r_state.cachedheight = fill(200)
    r_state.cacheddistance = fill(200)
    r_state.cachedxstep = fill(200)
    r_state.cachedystep = fill(200)
    r_state.screenheightarray = fill(320)
    r_state.negonearray = fill(320)
    r_state.ylookup = fill(832)         -- MAXHEIGHT
    r_state.columnofs = fill(1120)      -- MAXWIDTH
end

-- View size change request (r_main.c setsizeneeded / setblocks / setdetail).
r_state.setsizeneeded = false
r_state.setblocks = 10
r_state.setdetail = 0

-- Lighting.
r_state.scalelight = {}
r_state.scalelightfixed = {}
r_state.zlight = {}
r_state.extralight = 0
r_state.fixedcolormap = 0 -- byte offset into colormaps.buffer; 0 = none

-- Function pointers (r_draw.c draw routines, selected by detail level).
r_state.colfunc = nil
r_state.basecolfunc = nil
r_state.fuzzcolfunc = nil
r_state.transcolfunc = nil
r_state.spanfunc = nil

-- ---------------------------------------------------------------------------
-- Column drawing state (r_draw.c dc_*).
-- ---------------------------------------------------------------------------

r_state.dc_colormap = 0
r_state.dc_x = 0
r_state.dc_yl = 0
r_state.dc_yh = 0
r_state.dc_iscale = 0
r_state.dc_texturemid = 0
r_state.dc_source = nil -- { buffer, offset }
r_state.dc_translation = 0
r_state.translationtables = nil -- { buffer, offset } (Z_Malloc'd buffer)

-- Span drawing state (r_plane.c ds_*).
r_state.ds_y = 0
r_state.ds_x1 = 0
r_state.ds_x2 = 0
r_state.ds_colormap = 0
r_state.ds_xfrac = 0
r_state.ds_yfrac = 0
r_state.ds_xstep = 0
r_state.ds_ystep = 0
r_state.ds_source = nil -- { buffer, offset }

-- ---------------------------------------------------------------------------
-- Wall state (r_segs.c rw_*).
-- ---------------------------------------------------------------------------

r_state.rw_normalangle = 0
r_state.rw_angle1 = 0
r_state.rw_x = 0
r_state.rw_stopx = 0
r_state.rw_centerangle = 0
r_state.rw_offset = 0
r_state.rw_distance = 0
r_state.rw_scale = 0
r_state.rw_scalestep = 0
r_state.rw_midtexturemid = 0
r_state.rw_toptexturemid = 0
r_state.rw_bottomtexturemid = 0

r_state.worldtop = 0
r_state.worldbottom = 0
r_state.worldhigh = 0
r_state.worldlow = 0
r_state.pixhigh = 0
r_state.pixlow = 0
r_state.pixhighstep = 0
r_state.pixlowstep = 0
r_state.topfrac = 0
r_state.topstep = 0
r_state.bottomfrac = 0
r_state.bottomstep = 0

r_state.walllights = nil

r_state.segtextured = false
r_state.markfloor = false
r_state.markceiling = false
r_state.maskedtexture = false
r_state.toptexture = 0
r_state.bottomtexture = 0
r_state.midtexture = 0
r_state.maskedtexturecol = nil -- current seg's masked texture column array

-- ---------------------------------------------------------------------------
-- BSP / seg globals (r_bsp.c / r_segs.h).
-- ---------------------------------------------------------------------------

r_state.curline = nil
r_state.sidedef = nil
r_state.linedef = nil
r_state.frontsector = nil
r_state.backsector = nil

r_state.drawsegs = {}
r_state.ds_p = 1

-- Preallocate the drawseg slots (C: static drawsegs[MAXDRAWSEGS]).
do
    for _ = 1, 256 do
        table.insert(r_state.drawsegs, {
            curline = nil, x1 = 0, x2 = 0,
            scale1 = 0, scale2 = 0, scalestep = 0,
            silhouette = 0, bsilheight = 0, tsilheight = 0,
            sprtopclip = nil, sprbottomclip = nil, maskedtexturecol = nil,
        })
    end
end

-- Clip segs (r_bsp.c solidsegs[]).
r_state.solidsegs = {}
r_state.newend = 1

-- Preallocate the solidsegs slots (C: static solidsegs[MAXSEGS]); the C
-- static array is zero-initialized, which matters for the crunch-loop stale
-- copies.
do
    for _ = 1, 32 do
        table.insert(r_state.solidsegs, { first = 0, last = 0 })
    end
end

-- ---------------------------------------------------------------------------
-- Planes (r_plane.c).
-- ---------------------------------------------------------------------------

r_state.visplanes = {}
r_state.lastvisplane = 1
r_state.floorplane = nil
r_state.ceilingplane = nil
r_state.floorfunc = nil
r_state.ceilingfunc = nil

r_state.openings = {}
r_state.lastopening = 1

r_state.floorclip = {}
r_state.ceilingclip = {}
r_state.spanstart = {}
r_state.spanstop = {}

r_state.planezlight = nil
r_state.planeheight = 0
r_state.yslope = {}
r_state.distscale = {}
r_state.basexscale = 0
r_state.baseyscale = 0
r_state.cachedheight = {}
r_state.cacheddistance = {}
r_state.cachedxstep = {}
r_state.cachedystep = {}

-- ---------------------------------------------------------------------------
-- View drawing buffers (r_draw.c).
-- ---------------------------------------------------------------------------

r_state.viewimage = nil -- i_video.I_VideoBuffer
r_state.ylookup = {}
r_state.columnofs = {}

-- ---------------------------------------------------------------------------
-- Sprites (r_things.c).
-- ---------------------------------------------------------------------------

r_state.pspritescale = 0
r_state.pspriteiscale = 0
r_state.spritelights = nil

r_state.negonearray = {}
r_state.screenheightarray = {}

r_state.mfloorclip = nil
r_state.mceilingclip = nil
r_state.spryscale = 0
r_state.sprtopscreen = 0

r_state.vissprites = {}
r_state.vissprite_p = 1
r_state.overflowsprite = nil
r_state.vsprsortedhead = nil

-- Preallocate the vissprite slots (C: static vissprites[MAXVISSPRITES]).
do
    for _ = 1, 128 do
        table.insert(r_state.vissprites, {
            prev = nil, next = nil, x1 = 0, x2 = 0,
            gx = 0, gy = 0, gz = 0, gzt = 0,
            startfrac = 0, scale = 0, xiscale = 0,
            texturemid = 0, patch = 0, colormap = 0, mobjflags = 0,
        })
    end
end

return r_state