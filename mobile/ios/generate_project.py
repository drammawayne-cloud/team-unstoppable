#!/usr/bin/env python3
"""Generate an ordinary Xcode project and provisional icons. No dependencies required."""
from pathlib import Path
import hashlib, json, plistlib, struct, zlib
ROOT = Path(__file__).resolve().parent
APP = ROOT / 'TeamUnstoppable'
PROJECT = ROOT / 'TeamUnstoppable.xcodeproj'

def uid(value): return hashlib.sha1(value.encode()).hexdigest()[:24].upper()
def quoted(value): return json.dumps(str(value))

def png(path, size=1024):
    """Original geometric TU development monogram; not the official team logo."""
    ink, gold = (20, 22, 18), (225, 184, 92)
    rows = []
    for y in range(size):
        row = bytearray([0])
        for x in range(size):
            dx, dy = x-size/2, y-size/2
            r = (dx*dx+dy*dy)**0.5
            color = gold if r < 440 else ink
            xx, yy = x*1024/size, y*1024/size
            t = (245<=xx<=460 and 305<=yy<=385) or (312<=xx<=393 and 380<=yy<=704)
            u = ((515<=xx<=595 or 680<=xx<=760) and 305<=yy<=585)
            rr = ((xx-637.5)**2 + (yy-582)**2)**0.5
            u = u or (yy>=582 and 42.5<=rr<=122.5)
            if t or u: color=ink
            row.extend(color)
        rows.append(bytes(row))
    def chunk(kind,data): return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows),9))+chunk(b'IEND',b''))

asset=APP/'Assets.xcassets'
asset.mkdir(parents=True,exist_ok=True)
(asset/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}},indent=2))
icon=asset/'AppIcon.appiconset'; icon.mkdir(exist_ok=True)
png(icon/'AppIcon.png')
(icon/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2))
art=asset/'RadioArtwork.imageset'; art.mkdir(exist_ok=True)
png(art/'RadioArtwork.png',512)
(art/'Contents.json').write_text(json.dumps({'images':[{'filename':'RadioArtwork.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))

info={
 'CFBundleDevelopmentRegion':'en', 'CFBundleDisplayName':'Team Unstoppable',
 'CFBundleExecutable':'$(EXECUTABLE_NAME)', 'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)',
 'CFBundleInfoDictionaryVersion':'6.0', 'CFBundleName':'$(PRODUCT_NAME)',
 'CFBundlePackageType':'APPL', 'CFBundleShortVersionString':'$(MARKETING_VERSION)',
 'CFBundleVersion':'$(CURRENT_PROJECT_VERSION)', 'LSRequiresIPhoneOS':True,
 'ITSAppUsesNonExemptEncryption':False, 'UIBackgroundModes':['audio'], 'UILaunchScreen':{},
 'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],
 'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],
 'CFBundleURLTypes':[{'CFBundleURLName':'com.oneteamunstoppable.app','CFBundleURLSchemes':['teamunstoppable']}]
}
(APP/'Info.plist').write_bytes(plistlib.dumps(info))
privacy={'NSPrivacyTracking':False,'NSPrivacyTrackingDomains':[],'NSPrivacyCollectedDataTypes':[],
 'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults','NSPrivacyAccessedAPITypeReasons':['CA92.1']}]}
(APP/'Resources/PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(privacy))

objects=[]
def obj(key,body): objects.append(f'{uid(key)} = {{ {body} }};'); return uid(key)
source_paths=sorted(APP.rglob('*.swift'))
resource_paths=[APP/'Resources/content.json',APP/'Resources/PrivacyInfo.xcprivacy',asset]
refs=[]; sources=[]; resources=[]
for path in source_paths+resource_paths+[APP/'Info.plist']:
    rel=path.relative_to(ROOT).as_posix()
    kind='sourcecode.swift' if path.suffix=='.swift' else ('folder.assetcatalog' if path==asset else ('text.plist.xml' if path.suffix in ['.plist','.xcprivacy'] else 'text.json'))
    ref=obj('ref:'+rel,f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quoted(rel)}; sourceTree = "<group>";')
    refs.append(ref)
    if path in source_paths or path in resource_paths:
        build=obj('build:'+rel,f'isa = PBXBuildFile; fileRef = {ref};')
        (sources if path in source_paths else resources).append(build)
product=obj('product','isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TeamUnstoppable.app; sourceTree = BUILT_PRODUCTS_DIR;')
products=obj('products',f'isa = PBXGroup; children = ({product},); name = Products; sourceTree = "<group>";')
main=obj('main',f'isa = PBXGroup; children = ({",".join(refs+[products])},); sourceTree = "<group>";')
source_phase=obj('sources',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(sources)},); runOnlyForDeploymentPostprocessing = 0;')
resource_phase=obj('resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(resources)},); runOnlyForDeploymentPostprocessing = 0;')
framework_phase=obj('frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
project_configs=[]; target_configs=[]
for name in ['Debug','Release']:
    project_settings='CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0;'
    project_configs.append(obj('project:'+name,f'isa = XCBuildConfiguration; buildSettings = {{ {project_settings} }}; name = {name};'))
    settings={
      'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','CODE_SIGN_STYLE':'Automatic','CURRENT_PROJECT_VERSION':'1',
      'DEVELOPMENT_TEAM':'','ENABLE_PREVIEWS':'YES','GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':'TeamUnstoppable/Info.plist',
      'IPHONEOS_DEPLOYMENT_TARGET':'17.0','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks',
      'MARKETING_VERSION':'0.1.0','PRODUCT_BUNDLE_IDENTIFIER':'com.oneteamunstoppable.app','PRODUCT_NAME':'$(TARGET_NAME)',
      'SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SUPPORTS_MACCATALYST':'NO','SWIFT_VERSION':'5.0',
      'TARGETED_DEVICE_FAMILY':'1,2','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if name=='Debug' else '-O',
      'DEBUG_INFORMATION_FORMAT':'dwarf' if name=='Debug' else 'dwarf-with-dsym',
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if name=='Debug' else '',
      'ENABLE_USER_SCRIPT_SANDBOXING':'YES'
    }
    settings_text=' '.join(f'{k} = {quoted(v)};' for k,v in settings.items())
    target_configs.append(obj('target:'+name,f'isa = XCBuildConfiguration; buildSettings = {{ {settings_text} }}; name = {name};'))
pc=obj('project-configs',f'isa = XCConfigurationList; buildConfigurations = ({",".join(project_configs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
tc=obj('target-configs',f'isa = XCConfigurationList; buildConfigurations = ({",".join(target_configs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target=obj('target',f'isa = PBXNativeTarget; buildConfigurationList = {tc}; buildPhases = ({source_phase},{framework_phase},{resource_phase},); buildRules = (); dependencies = (); name = TeamUnstoppable; productName = TeamUnstoppable; productReference = {product}; productType = "com.apple.product-type.application";')
project=obj('project',f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{ {target} = {{ CreatedOnToolsVersion = 16.0; ProvisioningStyle = Automatic; }}; }}; }}; buildConfigurationList = {pc}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base,); mainGroup = {main}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target},);')
PROJECT.mkdir(exist_ok=True)
(PROJECT/'project.pbxproj').write_text('// !$*UTF8*$!\n{\narchiveVersion = 1;\nclasses = {};\nobjectVersion = 56;\nobjects = {\n'+'\n'.join(objects)+f'\n}};\nrootObject = {project};\n}}\n')
shared=PROJECT/'xcshareddata/xcschemes'; shared.mkdir(parents=True,exist_ok=True)
ref=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="TeamUnstoppable.app" BlueprintName="TeamUnstoppable" ReferencedContainer="container:TeamUnstoppable.xcodeproj"/>'
(shared/'TeamUnstoppable.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(PROJECT)
