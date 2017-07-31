$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

function Create-DownloadFolder {
    $files = @"
#TYPE Selected.System.IO.DirectoryInfo
"FullName","Mode"
"TestDrive:\Download\Arne Dahl","da---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E1 The Blinded Man","da---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E1 The Blinded Man\Arne Dahl - E1 The Blinded Man Part1.mp4","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E1 The Blinded Man\Arne Dahl - E1 The Blinded Man Part2.mp4","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E2 Bad Blood","da---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E2 Bad Blood\Arne Dahl - E2 Bad Blood Part1.mp4","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E2 Bad Blood\Arne Dahl - E2 Bad Blood Part2.mp4","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E3 To the top of the Mountain","da---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E3 To the top of the Mountain\Arne Dahl - E3 To The Top of the Mountain Part1.mp4","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E3 To the top of the Mountain\Arne Dahl - E3 To The Top of the Mountain Part2.mp4","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E4 Many Waters","da---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E4 Many Waters\Arne Dahl - E4 Many Waters Part1.avi","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E4 Many Waters\Arne Dahl - E4 Many Waters Part1.srt","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E4 Many Waters\Arne Dahl - E4 Many Waters Part2.avi","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E4 Many Waters\Arne Dahl - E4 Many Waters Part2.srt","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E5 Europe Blues","da---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E5 Europe Blues\Arne Dahl - E5 Europe Blues Part1.avi","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E5 Europe Blues\Arne Dahl - E5 Europe Blues Part1.srt","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E5 Europe Blues\Arne Dahl - E5 Europe Blues Part1mm.srt","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E5 Europe Blues\Arne Dahl - E5 Europe Blues Part2.avi","-a---"
"TestDrive:\Download\Arne Dahl\Arne Dahl - E5 Europe Blues\Arne Dahl - E5 Europe Blues Part2.srt","-a---"
"TestDrive:\Download\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa","da---"
"TestDrive:\Download\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa.avi","-a---"
"TestDrive:\Download\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa.idx","-a---"
"TestDrive:\Download\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa.sub","-a---"
"TestDrive:\Download\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa\Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa.tbn","-a---"
"TestDrive:\Download\Bilar.2.2011.SWEDiSH.DvDRip.x264-TaSTe1337","da---"
"TestDrive:\Download\Bilar.2.2011.SWEDiSH.DvDRip.x264-TaSTe1337\Bilar.2.2011.SWEDiSH.DvDRip.x264-TaSTe1337.mp4","-a---"
"TestDrive:\Download\Bilar.2.2011.SWEDiSH.DvDRip.x264-TaSTe1337\Bilar.2.2011.SWEDiSH.DvDRip.x264-TaSTe1337.nfo","-a---"
"TestDrive:\Download\Bilar.2006.SWEDiSH.AC3.DVDRip.XviD-nickecross","da---"
"TestDrive:\Download\Bilar.2006.SWEDiSH.AC3.DVDRip.XviD-nickecross\Bilar.2006.SWEDiSH.AC3.DVDRip.XviD-nickecross.avi","-a---"
"TestDrive:\Download\Bilar.2006.SWEDiSH.AC3.DVDRip.XviD-nickecross\Dreamseed.nu.txt","-a---"
"TestDrive:\Download\Divergent (2014)","da---"
"TestDrive:\Download\Divergent (2014)\Divergent.2014.720p.BluRay.x264.YIFY.mp4","-a---"
"TestDrive:\Download\Divergent (2014)\Divergent.2014.720p.BluRay.x264.YIFY.srt","-a---"
"TestDrive:\Download\Fortitude","da---"
"TestDrive:\Download\Fortitude S01E11 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude S01E11 WEB-DL XviD-FUM[ettv]\Fortitude.S01E11.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude S01E11 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude S01E12 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude S01E12 WEB-DL XviD-FUM[ettv]\Fortitude.S01E12.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude S01E12 WEB-DL XviD-FUM[ettv]\Fortitude.S01E12.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude S01E12 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E03 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E03 WEB-DL XviD-FUM[ettv]\Fortitude.S01E03.WEB-DL.XviD-FUM[ettv].avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E03 WEB-DL XviD-FUM[ettv]\Fortitude.S01E03.WEB-DL.XviD-FUM[ettv].srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E03 WEB-DL XviD-FUM[ettv]\Torrent Downloaded From ExtraTorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E04 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E04 WEB-DL XviD-FUM[ettv]\Fortitude.S01E04.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E04 WEB-DL XviD-FUM[ettv]\Fortitude.S01E04.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E04 WEB-DL XviD-FUM[ettv]\Torrent Downloaded From ExtraTorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E05 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E05 WEB-DL XviD-FUM[ettv]\Fortitude.S01E05.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E05 WEB-DL XviD-FUM[ettv]\Fortitude.S01E05.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E05 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E06 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E06 WEB-DL XviD-FUM[ettv]\Fortitude.S01E06.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E06 WEB-DL XviD-FUM[ettv]\Fortitude.S01E06.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E06 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E07 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E07 WEB-DL XviD-FUM[ettv]\Fortitude.S01E07.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E07 WEB-DL XviD-FUM[ettv]\Fortitude.S01E07.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E07 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E08 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E08 WEB-DL XviD-FUM[ettv]\Fortitude.S01E08.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E08 WEB-DL XviD-FUM[ettv]\Fortitude.S01E08.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E08 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E09 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E09 WEB-DL XviD-FUM[ettv]\Fortitude.S01E09.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E09 WEB-DL XviD-FUM[ettv]\Fortitude.S01E09.WEB-DL.XviD-FUM.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E09 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E10 WEB-DL XviD-FUM[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude S01E10 WEB-DL XviD-FUM[ettv]\Fortitude.S01E10.WEB-DL.XviD-FUM.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude S01E10 WEB-DL XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS[ettv]","da---"
"TestDrive:\Download\Fortitude\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS[ettv]\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS.mp4","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS[ettv]\fortitude.s01e01.internal.hdtv.x264-killers.nfo","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS[ettv]\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E01.INTERNAL.HDTV.x264-KILLERS[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit","da---"
"TestDrive:\Download\Fortitude\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBi.eng.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit.ita.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit\Fortitude.S01e02.Episode.Two.AlgernonWood-BlackBit.srt","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG","da---"
"TestDrive:\Download\Fortitude\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG.avi","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG.nfo","-a---"
"TestDrive:\Download\Fortitude\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG\Fortitude.S01E02.WEB-DL.XviD.MP3-RARBG.srt","-a---"
"TestDrive:\Download\Game of Thrones S05E02 WEBRip XviD-FUM[ettv]","da---"
"TestDrive:\Download\Game of Thrones S05E02 WEBRip XviD-FUM[ettv]\Game.of.Thrones.S05E02.WEBRip.XviD-FUM.avi","-a---"
"TestDrive:\Download\Game of Thrones S05E02 WEBRip XviD-FUM[ettv]\Game.of.Thrones.S05E02.WEBRip.XviD-FUM.srt","-a---"
"TestDrive:\Download\Game of Thrones S05E02 WEBRip XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Game of Thrones S05E03 WEBRip XviD-FUM[ettv]","da---"
"TestDrive:\Download\Game of Thrones S05E03 WEBRip XviD-FUM[ettv]\Game.of.Thrones.S05E03.WEBRip.XviD-FUM.avi","-a---"
"TestDrive:\Download\Game of Thrones S05E03 WEBRip XviD-FUM[ettv]\Game.of.Thrones.S05E03.WEBRip.XviD-FUM.srt","-a---"
"TestDrive:\Download\Game of Thrones S05E03 WEBRip XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Game of Thrones S05E04 WEBRip XviD-FUM[ettv]","da---"
"TestDrive:\Download\Game of Thrones S05E04 WEBRip XviD-FUM[ettv]\Game.of.Thrones.S05E04.WEBRip.XviD-FUM.avi","-a---"
"TestDrive:\Download\Game of Thrones S05E04 WEBRip XviD-FUM[ettv]\Game.of.Thrones.S05E04.WEBRip.XviD-FUM.srt","-a---"
"TestDrive:\Download\Game of Thrones S05E04 WEBRip XviD-FUM[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E01.HDTV.x264-Xclusive.mp4","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E01.HDTV.x264-Xclusive.srt","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E01.WEBRip.XviD-FUM.avi","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E01.WEBRip.XviD-FUM.srt","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E02.HDTV.x264-Xclusive.mp4","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E02.HDTV.x264-Xclusive.srt","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E03.HDTV.x264-Xclusive4iPT.mp4","-a---"
"TestDrive:\Download\Game.of.Thrones.S05E04.HDTV.x264-Xclusive4iPT.mp4","-a---"
"TestDrive:\Download\Guitar.Hero.III.PC.The.Ultimate.Collection","da---"
"TestDrive:\Download\Guitar.Hero.III.PC.The.Ultimate.Collection\GH3-TUC-Disc1-Essentials.iso","-a---"
"TestDrive:\Download\Guitar.Hero.III.PC.The.Ultimate.Collection\GH3-TUC-Disc2-Customs.iso","-a---"
"TestDrive:\Download\Guitar.Hero.III.PC.The.Ultimate.Collection\SongLists.txt","-a---"
"TestDrive:\Download\Jordskott - S01E08 - 1280x720 - H.264 - SweSub.mp4","da---"
"TestDrive:\Download\Jordskott - S01E08 - 1280x720 - H.264 - SweSub.mp4\Jordskott - S01E08.mp4","-a---"
"TestDrive:\Download\Jordskott - S01E08 - 1280x720 - H.264 - SweSub.mp4\Jordskott - S01E08.srt","-a---"
"TestDrive:\Download\The Hobbit The Battle of the Five Armies (2014) [1080p]","da---"
"TestDrive:\Download\The Hobbit The Battle of the Five Armies (2014) [1080p]\The.Hobbit.The.Battle.of.the.Five.Armies.2014.1080p.BluRay.x264.YIFY.mp4","-a---"
"TestDrive:\Download\The Hobbit The Battle of the Five Armies (2014) [1080p]\The.Hobbit.The.Battle.of.the.Five.Armies.2014.1080p.BluRay.x264.YIFY.srt","-a---"
"TestDrive:\Download\The Hobbit The Battle of the Five Armies (2014) [1080p]\WWW.YTS.RE.jpg","-a---"
"TestDrive:\Download\The Killing Season 1","da---"
"TestDrive:\Download\The Killing Season 1\KABLAM!!!.txt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E01-E02.REPACK.HDTV.XviD-FQM.[VTV].Pilot-The.Cage.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E01-E02.REPACK.HDTV.XviD-FQM.[VTV].Pilot-The.Cage.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E03.HDTV.XviD-FQM.[VTV].El.Diablo.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E03.HDTV.XviD-FQM.[VTV].El.Diablo.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E04.HDTV.XviD-ASAP.[VTV].A.Soundless.Echo.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E04.HDTV.XviD-ASAP.[VTV].A.Soundless.Echo.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E05.HDTV.XviD-FQM.[VTV].Super.8.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E05.HDTV.XviD-FQM.[VTV].Super.8.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E06.HDTV.XviD-FQM.[VTV].What.You.Have.Left.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E06.HDTV.XviD-FQM.[VTV].What.You.Have.Left.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E07.HDTV.XviD-FQM.[VTV].Vengeance.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E07.HDTV.XviD-FQM.[VTV].Vengeance.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E08.HDTV.XviD-FQM.[VTV].Stonewalled.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E09.REPACK.REAL.PROPER.HDTV.XviD-FQM.[VTV].Undertow.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E09.REPACK.REAL.PROPER.HDTV.XviD-FQM.[VTV].Undertow.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E10.HDTV.XviD-FQM.[VTV].Ill.Let.You.Know.When.I.Get.There.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E10.HDTV.XviD-FQM.[VTV].Ill.Let.You.Know.When.I.Get.There.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E11.HDTV.XviD-FQM.[VTV].Missing.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E11.HDTV.XviD-FQM.[VTV].Missing.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E12.HDTV.XviD-FQM.[VTV].Beau.Soleil.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E12.HDTV.XviD-FQM.[VTV].Beau.Soleil.srt","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E13.HDTV.XviD-FQM.[VTV].Orpheus.Descending.avi","-a---"
"TestDrive:\Download\The Killing Season 1\The.Killing.S01E13.HDTV.XviD-FQM.[VTV].Orpheus.Descending.srt","-a---"
"TestDrive:\Download\The Killing Season 1\TheKilling.jpg","-a---"
"TestDrive:\Download\The Maze Runner (2014)","da---"
"TestDrive:\Download\The Maze Runner (2014)\The.Maze.Runner.2014.720p.BluRay.x264.YIFY.mp4","-a---"
"TestDrive:\Download\The Maze Runner (2014)\The.Maze.Runner.2014.720p.BluRay.x264.YIFY.srt","-a---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]","da---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]\Sample","da---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]\Sample\the.blacklist.212.hdtv-lol.sample.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]\the.blacklist.212.hdtv-lol.nfo","-a---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]\The.Blacklist.S02E12.HDTV.x264-LOL.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]\The.Blacklist.S02E12.HDTV.x264-LOL.srt","-a---"
"TestDrive:\Download\The.Blacklist.S02E12.HDTV.x264-LOL[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\The.Blacklist.S02E13.HDTV.x264-LOL.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E13.HDTV.x264-LOL.srt","-a---"
"TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]","da---"
"TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]\Sample","da---"
"TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]\Sample\the.blacklist.214.hdtv-lol.sample.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]\the.blacklist.214.hdtv-lol.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]\the.blacklist.214.hdtv-lol.nfo","-a---"
"TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]","da---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]\Sample","da---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]\Sample\the.blacklist.215.hdtv-lol.sample.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]\the.blacklist.215.hdtv-lol.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]\the.blacklist.215.hdtv-lol.srt","-a---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]\the.blacklist.215.hdtv-lol.nfo","-a---"
"TestDrive:\Download\The.Blacklist.S02E15.HDTV.x264-LOL[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\The.Blacklist.S02E16.HDTV.x264-LOL[ettv]","da---"
"TestDrive:\Download\The.Blacklist.S02E16.HDTV.x264-LOL[ettv]\Sample","da---"
"TestDrive:\Download\The.Blacklist.S02E16.HDTV.x264-LOL[ettv]\Sample\the.blacklist.216.hdtv-lol.sample.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E16.HDTV.x264-LOL[ettv]\the.blacklist.216.hdtv-lol.mp4","-a---"
"TestDrive:\Download\The.Blacklist.S02E16.HDTV.x264-LOL[ettv]\the.blacklist.216.hdtv-lol.nfo","-a---"
"TestDrive:\Download\The.Blacklist.S02E16.HDTV.x264-LOL[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]","da---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]\Sample","da---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]\Sample\sample-the.walking.dead.s05e15.proper.hdtv.x264-batv.mp4","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV.mp4","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]\the.walking.dead.s05e15.proper.hdtv.x264-batv.nfo","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV.srt","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E15.PROPER.HDTV.x264-BATV[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]","da---"
"TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]\Sample","da---"
"TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]\Sample\sample-the.walking.dead.s05e16.proper.hdtv.x264-killers.mp4","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS.mp4","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]\the.walking.dead.s05e16.proper.hdtv.x264-killers.nfo","-a---"
"TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]\Torrent-Downloaded-From-extratorrent.cc.txt","-a---"
"TestDrive:\Download\v24164","-a---"
"TestDrive:\Download\v241641","-a---"
"TestDrive:\Download\Wildest.Islands.Series.2.3of5.Vancouver.Island.Rivers.Of.Life.540p.PDTV.x264.AAC.MVGroup.org.mp4","-a---"
"TestDrive:\Download\The.Handmaid's.Tale.S01E01.Offred.720p.WEBRip.2CH.x265.HEVC-PSA.mkv","-a----"
"TestDrive:\Download\The.Handmaid's.Tale.S01E02.Birth.Day.720p.WEBRip.2CH.x265.HEVC-PSA.mkv","-a----"
"@ | ConvertFrom-Csv
    $files | %{
        $type = "File"
        if ($_.Mode -match "d") {
            $type = "Dir"
        }
        ni $_.FullName -ItemType $type | Out-Null
    }
}

function Get-UnexpectedItemsLeft {
    $itemsLeft = New-Object System.Collections.ArrayList
    gci TestDrive:\Download | %{ $itemsLeft.Add($_.Name) | Out-Null }
    $itemsLeft.Remove("Arne Dahl")
    $itemsLeft.Remove("Bamse.Och.Tjuvstaden.2014.Swedish.480p.Dvd.Ac3-YstaJeppa")
    $itemsLeft.Remove("Bilar.2.2011.SWEDiSH.DvDRip.x264-TaSTe1337")
    $itemsLeft.Remove("Bilar.2006.SWEDiSH.AC3.DVDRip.XviD-nickecross")
    $itemsLeft.Remove("Divergent (2014)")
    $itemsLeft.Remove("Guitar.Hero.III.PC.The.Ultimate.Collection")
    $itemsLeft.Remove("The Hobbit The Battle of the Five Armies (2014) [1080p]")
    $itemsLeft.Remove("The Maze Runner (2014)")
    $itemsLeft.Remove("v24164")
    $itemsLeft.Remove("v241641")
    $itemsLeft.Remove("Wildest.Islands.Series.2.3of5.Vancouver.Island.Rivers.Of.Life.540p.PDTV.x264.AAC.MVGroup.org.mp4")
    if ($itemsLeft.Count -ne 0) {
        $itemsLeft | %{ Write-Warning "Found unexpeced item: $_" }
    }
    return $itemsLeft 
}

Describe "Synology" {
    Context "Get-Movies" {
        Create-DownloadFolder
        $movies = Get-Movies -Path "Testdrive:\"

        It "finds some movies" {
            @($movies).Length | Should Not Be 0
        }

        It "does not find folders with movie extensions" {
            $foldersWithoutFiles = $movies | ?{ $_.Mode -match "d" }
            @($foldersWithoutFiles).Length | Should Be 0
        }
    }

    Context "Move-Movies" {
        Create-DownloadFolder
        Mock Invoke-DownloadSubtitle {}
        Move-Movie -Path TestDrive:\Download -Destination TestDrive:\Movies -TidyUp #-Verbose

        It "should have trimmed strange characters in the series name" {
            Test-Path TestDrive:\Movies\Jordskott | Should Be $true
        }

        It "should not contain any unexpected files in source folder" {
            @(Get-UnexpectedItemsLeft).Length | Should Be 0
        }

        It "should rename files with sXXeYY in its folder name without uploader tag" {
            "TestDrive:\Movies\The Blacklist\S02\The.Blacklist.S02E14.HDTV.x264-LOL.mp4" | Should Exist
        }

        It "should also rename subtitles when xXXeYY is only present in its folder name" {
            "TestDrive:\Movies\The Blacklist\S02\The.Blacklist.S02E15.HDTV.x264-LOL.srt" | Should Exist
        }

        It "should not rename files with sXXeYY in its base name" {
            Test-Path -LiteralPath "TestDrive:\Movies\The Killing\S01\The.Killing.S01E13.HDTV.XviD-FQM.[VTV].Orpheus.Descending.avi" | Should Be $true
        }

        It "should copy subtiltes next to files with sXXeYY in its base name" {
            Test-Path -LiteralPath "TestDrive:\Movies\Fortitude\S01\Fortitude.S01E12.WEB-DL.XviD-FUM.srt" | Should Be $true
        }
    }

    Context "Download Subtitles with Move-Movies" {
        Mock Is-SubtitleMissingSql { return $false }
        Mock Save-MissingSubtitleSql {}
        Create-DownloadFolder

        It "should download subtitles when sXXyYY is only in folder" {
            Move-Movie -Path "TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]" -Destination TestDrive:\Movies
            "TestDrive:\Movies\The Blacklist\S02\The.Blacklist.S02E14.HDTV.x264-LOL.srt" | Should Exist
        }

        It "should download subtitles when sXXyYY is in file base name" {
            Move-Movie -Path "TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]" -Destination TestDrive:\Movies
            "TestDrive:\Movies\The Walking Dead\S05\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS.srt" | Should Exist
        }

        It "should be able to search and save movie titles with apostrophes" {
            Mock Write-Warning {} # Supress warning output of that no subtitle exists for the movie
            Move-Movie -Path "TestDrive:\Download\The.Handmaid's.Tale.S01E01.Offred.720p.WEBRip.2CH.x265.HEVC-PSA.mkv" -Destination TestDrive:\Movies
            Assert-MockCalled Is-SubtitleMissingSql -ParameterFilter { $Text -eq "English The.Handmaid''s.Tale.S01E01.Offred.720p.WEBRip.2CH.x265.HEVC-PSA" } -Times 1 -Exactly
            Assert-MockCalled Save-MissingSubtitleSql -ParameterFilter { $Text -eq "English The.Handmaid''s.Tale.S01E01.Offred.720p.WEBRip.2CH.x265.HEVC-PSA" } -Times 1 -Exactly
        }
    }

    Context "Download Subtitles with Get-MissingSubtitles" {
        Mock Is-SubtitleMissingSql { return $false }
        Create-DownloadFolder

        It "should download subtitles when sXXyYY is only in folder" {
            Get-MissingSubtitles -Path "TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]"
            Test-Path -LiteralPath "TestDrive:\Download\The.Blacklist.S02E14.HDTV.x264-LOL[ettv]\the.blacklist.214.hdtv-lol.srt" | Should Be $true
        }

        It "should download subtitles when sXXyYY is in file base name" {
            Get-MissingSubtitles -Path "TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]"
            Test-Path -LiteralPath "TestDrive:\Download\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS[ettv]\The.Walking.Dead.S05E16.PROPER.HDTV.x264-KILLERS.srt" | Should Be $true
        }
    }
}
