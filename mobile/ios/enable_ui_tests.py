#!/usr/bin/env python3
"""Add an isolated XCTest UI target to the generated project. Runtime source is unchanged."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib
ROOT = Path(__file__).resolve().parent
PROJECT = ROOT / 'TeamUnstoppable.xcodeproj'
pbx = PROJECT / 'project.pbxproj'
scheme = PROJECT / 'xcshareddata/xcschemes/TeamUnstoppable.xcscheme'
uid = lambda value: hashlib.sha1(value.encode()).hexdigest()[:24].upper()
text = pbx.read_text()
if 'name = TeamUnstoppableUITests;' in text:
    print('UI target already present'); raise SystemExit(0)
objects = []
def obj(key, body):
    objects.append(f'{uid(key)} = {{ {body} }};')
    return uid(key)
file = obj('ui-file', 'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = UITests/SmokeTests.swift; sourceTree = "<group>";')
build = obj('ui-build', f'isa = PBXBuildFile; fileRef = {file};')
product = obj('ui-product', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TeamUnstoppableUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
sources = obj('ui-sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({build},); runOnlyForDeploymentPostprocessing = 0;')
frameworks = obj('ui-frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
resources = obj('ui-resources', 'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
proxy = obj('ui-proxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("target")}; remoteInfo = TeamUnstoppable;')
dep = obj('ui-dep', f'isa = PBXTargetDependency; target = {uid("target")}; targetProxy = {proxy};')
configs = []
for name in ('Debug', 'Release'):
    settings = 'CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = ""; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0; PRODUCT_BUNDLE_IDENTIFIER = com.oneteamunstoppable.app.UITests; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = iphoneos; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SWIFT_VERSION = 5.0; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; TARGETED_DEVICE_FAMILY = "1,2"; TEST_TARGET_NAME = TeamUnstoppable;'
    configs.append(obj('ui-config-'+name, f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {name};'))
clist = obj('ui-configs', f'isa = XCConfigurationList; buildConfigurations = ({",".join(configs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target = obj('ui-target', f'isa = PBXNativeTarget; buildConfigurationList = {clist}; buildPhases = ({sources},{frameworks},{resources},); buildRules = (); dependencies = ({dep},); name = TeamUnstoppableUITests; productName = TeamUnstoppableUITests; productReference = {product}; productType = "com.apple.product-type.bundle.ui-testing";')
text = text.replace('objects = {\n', 'objects = {\n'+'\n'.join(objects)+'\n', 1)
text = text.replace(f'{uid("main")} = {{ isa = PBXGroup; children = (', f'{uid("main")} = {{ isa = PBXGroup; children = ({file},', 1)
text = text.replace(f'{uid("products")} = {{ isa = PBXGroup; children = (', f'{uid("products")} = {{ isa = PBXGroup; children = ({product},', 1)
text = text.replace(f'targets = ({uid("target")},);', f'targets = ({uid("target")},{target},);', 1)
pbx.write_text(text)
xml = ET.parse(scheme)
attrs = dict(BuildableIdentifier='primary', BlueprintIdentifier=target, BuildableName='TeamUnstoppableUITests.xctest', BlueprintName='TeamUnstoppableUITests', ReferencedContainer='container:TeamUnstoppable.xcodeproj')
entries = xml.getroot().find('BuildAction/BuildActionEntries')
entry = ET.SubElement(entries, 'BuildActionEntry', dict(buildForTesting='YES', buildForRunning='NO', buildForProfiling='NO', buildForArchiving='NO', buildForAnalyzing='YES'))
ET.SubElement(entry, 'BuildableReference', attrs)
testables = xml.getroot().find('TestAction/Testables')
ref = ET.SubElement(testables, 'TestableReference', dict(skipped='NO'))
ET.SubElement(ref, 'BuildableReference', attrs)
xml.write(scheme, encoding='utf-8', xml_declaration=True)
print('Native UI test target enabled; application runtime source unchanged.')
