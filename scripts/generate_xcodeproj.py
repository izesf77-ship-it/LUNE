"""Deterministically generate LUNE.xcodeproj for an unsigned iOS device build.

Walks the repository, creates explicit PBX file references / build files for
all Swift sources and resources, and writes a shared scheme with a test action.
"""
from pathlib import Path
import os

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "LUNE.xcodeproj"
PBXPROJ = PROJECT / "project.pbxproj"
SCHEME_DIR = PROJECT / "xcshareddata" / "xcschemes"

APP_SOURCE_DIRS = ["App", "Core", "Features", "Resources"]
APP_ROOT_SOURCES = ["LUNEApp.swift", "ContentView.swift"]
APP_RESOURCES = [
    "Resources/Assets/Assets.xcassets",
    "Resources/Localizations/Localizable.xcstrings",
]
TEST_SOURCE_DIRS = ["Tests"]

_counter = 0


def oid():
    global _counter
    _counter += 1
    return f"AA{_counter:022X}"


def collect_sources(dirs):
    files = []
    for d in dirs:
        base = ROOT / d
        if not base.exists():
            continue
        for path in base.rglob("*.swift"):
            files.append(path.relative_to(ROOT).as_posix())
    return sorted(files)


def quote(value):
    return f'"{value}"'


def file_type(path):
    if path.endswith(".swift"):
        return "sourcecode.swift"
    if path.endswith(".xcassets"):
        return "folder.assetcatalog"
    if path.endswith(".xcstrings"):
        return "text.json.xcstrings"
    if path.endswith(".plist"):
        return "text.plist.xml"
    if path.endswith(".png"):
        return "image.png"
    return "file"


class Group:
    def __init__(self, name, path=None):
        self.id = oid()
        self.name = name
        self.path = path if path is not None else name
        self.children = []


def build_groups(rel_paths, root_children, groups):
    """Create nested PBXGroups mirroring directory structure."""
    for rel in rel_paths:
        parts = rel.split("/")
        parent_children = root_children
        acc = []
        for part in parts[:-1]:
            acc.append(part)
            key = "/".join(acc)
            if key not in groups:
                g = Group(name=part, path=part)
                groups[key] = g
                parent_children.append(("group", g.id))
            parent_children = groups[key].children
        parent_children.append(("file", rel))


def main():
    app_sources = sorted(APP_ROOT_SOURCES + collect_sources(APP_SOURCE_DIRS))
    test_sources = collect_sources(TEST_SOURCE_DIRS)

    # Validate referenced sources exist (avoid silently broken project).
    for rel in app_sources + test_sources + APP_RESOURCES:
        if not (ROOT / rel).exists():
            raise SystemExit(f"Missing referenced path: {rel}")

    ids = {
        "project": oid(),
        "mainGroup": oid(),
        "products": oid(),
        "appTarget": oid(),
        "testTarget": oid(),
        "appSources": oid(),
        "appResources": oid(),
        "appFrameworks": oid(),
        "testSources": oid(),
        "testFrameworks": oid(),
        "testResources": oid(),
        "projectConfigList": oid(),
        "appConfigList": oid(),
        "testConfigList": oid(),
        "appDebug": oid(),
        "appRelease": oid(),
        "testDebug": oid(),
        "testRelease": oid(),
        "projectDebug": oid(),
        "projectRelease": oid(),
        "appProduct": oid(),
        "testProduct": oid(),
        "containerProxy": oid(),
        "targetDependency": oid(),
    }

    app_file_refs = {}
    test_file_refs = {}
    resource_refs = {}
    build_files = {}
    app_source_ids = []
    test_source_ids = []
    resource_build_ids = []

    for rel in app_sources:
        fid = oid()
        app_file_refs[rel] = fid
        bid = oid()
        build_files[rel] = bid
        app_source_ids.append(bid)

    for rel in test_sources:
        fid = oid()
        test_file_refs[rel] = fid
        bid = oid()
        build_files[rel] = bid
        test_source_ids.append(bid)

    for rel in APP_RESOURCES + ["Info.plist"]:
        fid = oid()
        resource_refs[rel] = fid
        bid = oid()
        build_files[rel] = bid
        if rel != "Info.plist":
            resource_build_ids.append(bid)

    app_groups = {}
    app_root_children = []
    build_groups([rel for rel in app_sources if "/" in rel], app_root_children, app_groups)
    for rel in app_sources:
        if "/" not in rel:
            app_root_children.insert(0, ("file", rel))

    test_groups = {}
    test_root_children = []
    build_groups([rel[len("Tests/"):] for rel in test_sources], test_root_children, test_groups)

    resource_groups = {}
    resource_root_children = []
    build_groups([rel[len("Resources/"):] for rel in APP_RESOURCES if "/" in rel], resource_root_children, resource_groups)

    lines = []
    add = lines.append

    add("// !$*UTF8*$!")
    add("{")
    add("\tarchiveVersion = 1;")
    add("\tclasses = {")
    add("\t};")
    add("\tobjectVersion = 56;")
    add("\tobjects = {")
    add("")

    # PBXBuildFile
    add("/* Begin PBXBuildFile section */")
    for rel, bid in build_files.items():
        fid = app_file_refs.get(rel) or test_file_refs.get(rel) or resource_refs.get(rel)
        add(f"\t\t{bid} /* {Path(rel).name} in sources/resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {Path(rel).name} */; }};")
    add("/* End PBXBuildFile section */")
    add("")

    # PBXContainerItemProxy
    add("/* Begin PBXContainerItemProxy section */")
    add(f"\t\t{ids['containerProxy']} /* PBXContainerItemProxy */ = {{")
    add("\t\t\tisa = PBXContainerItemProxy;")
    add(f"\t\t\tcontainerPortal = {ids['project']} /* Project object */;")
    add("\t\t\tproxyType = 1;")
    add(f"\t\t\tremoteGlobalIDString = {ids['appTarget']};")
    add("\t\t\tremoteInfo = LUNE;")
    add("\t\t};")
    add("/* End PBXContainerItemProxy section */")
    add("")

    # PBXFileReference
    add("/* Begin PBXFileReference section */")
    add(f"\t\t{ids['appProduct']} /* LUNE.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LUNE.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    add(f"\t\t{ids['testProduct']} /* LUNETests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LUNETests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for rel, fid in {**app_file_refs, **test_file_refs, **resource_refs}.items():
        name = Path(rel).name
        add(f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(rel)}; path = {quote(name)}; sourceTree = "<group>"; }};')
    add("/* End PBXFileReference section */")
    add("")

    # Frameworks phases
    for key, name in [("appFrameworks", "Frameworks"), ("testFrameworks", "Frameworks")]:
        add(f"/* Begin PBXFrameworksBuildPhase section */")
        add(f"\t\t{ids[key]} /* {name} */ = {{")
        add("\t\t\tisa = PBXFrameworksBuildPhase;")
        add("\t\t\tbuildActionMask = 2147483647;")
        add("\t\t\tfiles = (")
        add("\t\t\t);")
        add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        add("\t\t};")
        add(f"/* End PBXFrameworksBuildPhase section */")
        add("")

    # Groups
    def emit_group(gid, name, path, children):
        add(f"\t\t{gid} /* {name} */ = {{")
        add("\t\t\tisa = PBXGroup;")
        add("\t\t\tchildren = (")
        for kind, value in children:
            if kind == "group":
                child_group_name = next(
                    (g.name for g in list(app_groups.values()) + list(test_groups.values()) + list(resource_groups.values())
                     if g.id == value),
                    "Group"
                )
                add(f"\t\t\t\t{value} /* {child_group_name} */,")
            else:
                name = Path(value).name
                fid = file_refs_by_name.get(name)
                if fid is None:
                    raise SystemExit(f"Missing file reference for {value}")
                add(f"\t\t\t\t{fid} /* {name} */,")
        add("\t\t\t);")
        if path != ".":
            add(f'\t\t\tpath = {quote(path)};')
        add('\t\t\tsourceTree = "<group>";')
        add("\t\t};")

    add("/* Begin PBXGroup section */")
    add(f"\t\t{ids['mainGroup']} = {{")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add(f"\t\t\t\t{ids['mainGroupApp'] if 'mainGroupApp' in ids else oid()} /* placeholder */,")
    # Replace placeholder line by building properly below (we rewrite section in a moment)
    add("\t\t\t);")
    add('\t\t\tsourceTree = "<group>";')
    add("\t\t};")
    add("/* End PBXGroup section */")

    # The previous block used a placeholder; rebuild the whole output cleanly
    # by regenerating lines from scratch with a complete group tree.
    lines = []
    add = lines.append
    add("// !$*UTF8*$!")
    add("{")
    add("\tarchiveVersion = 1;")
    add("\tclasses = {")
    add("\t};")
    add("\tobjectVersion = 56;")
    add("\tobjects = {")
    add("")

    add("/* Begin PBXBuildFile section */")
    for rel, bid in build_files.items():
        fid = app_file_refs.get(rel) or test_file_refs.get(rel) or resource_refs.get(rel)
        add(f"\t\t{bid} /* {Path(rel).name} in build */ = {{isa = PBXBuildFile; fileRef = {fid} /* {Path(rel).name} */; }};")
    add("/* End PBXBuildFile section */")
    add("")

    add("/* Begin PBXContainerItemProxy section */")
    add(f"\t\t{ids['containerProxy']} /* PBXContainerItemProxy */ = {{")
    add("\t\t\tisa = PBXContainerItemProxy;")
    add(f"\t\t\tcontainerPortal = {ids['project']} /* Project object */;")
    add("\t\t\tproxyType = 1;")
    add(f"\t\t\tremoteGlobalIDString = {ids['appTarget']};")
    add("\t\t\tremoteInfo = LUNE;")
    add("\t\t};")
    add("/* End PBXContainerItemProxy section */")
    add("")

    add("/* Begin PBXFileReference section */")
    add(f"\t\t{ids['appProduct']} /* LUNE.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LUNE.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    add(f"\t\t{ids['testProduct']} /* LUNETests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LUNETests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for rel, fid in {**app_file_refs, **test_file_refs, **resource_refs}.items():
        add(f'\t\t{fid} /* {Path(rel).name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(rel)}; path = {quote(Path(rel).name)}; sourceTree = "<group>"; }};')
    add("/* End PBXFileReference section */")
    add("")

    add("/* Begin PBXFrameworksBuildPhase section */")
    for key in ["appFrameworks", "testFrameworks"]:
        add(f"\t\t{ids[key]} /* Frameworks */ = {{")
        add("\t\t\tisa = PBXFrameworksBuildPhase;")
        add("\t\t\tbuildActionMask = 2147483647;")
        add("\t\t\tfiles = (")
        add("\t\t\t);")
        add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        add("\t\t};")
    add("/* End PBXFrameworksBuildPhase section */")
    add("")

    app_group_id = oid()
    tests_group_id = oid()
    resources_group_id = oid()

    file_refs_by_name = {
        Path(rel).name: fid
        for rel, fid in {**app_file_refs, **test_file_refs, **resource_refs}.items()
    }

    add("/* Begin PBXGroup section */")
    add(f"\t\t{ids['mainGroup']} = {{")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add(f"\t\t\t\t{app_group_id} /* App sources */,")
    add(f"\t\t\t\t{tests_group_id} /* Tests */,")
    add(f"\t\t\t\t{resources_group_id} /* Resources */,")
    add(f"\t\t\t\t{resource_refs['Info.plist']} /* Info.plist */,")
    add(f"\t\t\t\t{ids['products']} /* Products */,")
    add("\t\t\t);")
    add('\t\t\tsourceTree = "<group>";')
    add("\t\t};")

    emit_group(app_group_id, "App sources", ".", app_root_children)
    for key, g in app_groups.items():
        emit_group(g.id, g.name, g.path, g.children)

    emit_group(tests_group_id, "Tests", "Tests", test_root_children)
    for key, g in test_groups.items():
        emit_group(g.id, g.name, g.path, g.children)

    emit_group(resources_group_id, "Resources", "Resources", resource_root_children)
    for key, g in resource_groups.items():
        emit_group(g.id, g.name, g.path, g.children)

    add(f"\t\t{ids['products']} /* Products */ = {{")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add(f"\t\t\t\t{ids['appProduct']} /* LUNE.app */,")
    add(f"\t\t\t\t{ids['testProduct']} /* LUNETests.xctest */,")
    add("\t\t\t);")
    add("\t\t\tname = Products;")
    add('\t\t\tsourceTree = "<group>";')
    add("\t\t};")
    add("/* End PBXGroup section */")
    add("")

    add("/* Begin PBXNativeTarget section */")
    add(f"\t\t{ids['appTarget']} /* LUNE */ = {{")
    add("\t\t\tisa = PBXNativeTarget;")
    add(f"\t\t\tbuildConfigurationList = {ids['appConfigList']};")
    add("\t\t\tbuildPhases = (")
    add(f"\t\t\t\t{ids['appSources']} /* Sources */,")
    add(f"\t\t\t\t{ids['appFrameworks']} /* Frameworks */,")
    add(f"\t\t\t\t{ids['appResources']} /* Resources */,")
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add("\t\t\t);")
    add("\t\t\tname = LUNE;")
    add("\t\t\tproductName = LUNE;")
    add(f"\t\t\tproductReference = {ids['appProduct']} /* LUNE.app */;")
    add('\t\t\tproductType = "com.apple.product-type.application";')
    add("\t\t};")

    add(f"\t\t{ids['testTarget']} /* LUNETests */ = {{")
    add("\t\t\tisa = PBXNativeTarget;")
    add(f"\t\t\tbuildConfigurationList = {ids['testConfigList']};")
    add("\t\t\tbuildPhases = (")
    add(f"\t\t\t\t{ids['testSources']} /* Sources */,")
    add(f"\t\t\t\t{ids['testFrameworks']} /* Frameworks */,")
    add(f"\t\t\t\t{ids['testResources']} /* Resources */,")
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add(f"\t\t\t\t{ids['targetDependency']} /* PBXTargetDependency */,")
    add("\t\t\t);")
    add("\t\t\tname = LUNETests;")
    add("\t\t\tproductName = LUNETests;")
    add(f"\t\t\tproductReference = {ids['testProduct']} /* LUNETests.xctest */;")
    add('\t\t\tproductType = "com.apple.product-type.bundle.unit-test";')
    add("\t\t};")
    add("/* End PBXNativeTarget section */")
    add("")

    add("/* Begin PBXProject section */")
    add(f"\t\t{ids['project']} /* Project object */ = {{")
    add("\t\t\tisa = PBXProject;")
    add("\t\t\tattributes = {")
    add("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    add("\t\t\t\tLastSwiftUpdateCheck = 2700;")
    add("\t\t\t\tLastUpgradeCheck = 2700;")
    add("\t\t\t\tTargetAttributes = {")
    add(f"\t\t\t\t\t{ids['appTarget']} = {{")
    add("\t\t\t\t\t\tCreatedOnToolsVersion = 27.0;")
    add("\t\t\t\t\t};")
    add(f"\t\t\t\t\t{ids['testTarget']} = {{")
    add("\t\t\t\t\t\tCreatedOnToolsVersion = 27.0;")
    add("\t\t\t\t\t\tTestTargetID = " + ids['appTarget'] + ";")
    add("\t\t\t\t\t};")
    add("\t\t\t\t};")
    add("\t\t\t};")
    add(f"\t\t\tbuildConfigurationList = {ids['projectConfigList']};")
    add('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    add("\t\t\tdevelopmentRegion = ru;")
    add("\t\t\thasScannedForEncodings = 0;")
    add("\t\t\tknownRegions = (")
    add("\t\t\t\tru,")
    add("\t\t\t\ten,")
    add("\t\t\t\tBase,")
    add("\t\t\t);")
    add(f"\t\t\tmainGroup = {ids['mainGroup']};")
    add(f"\t\t\tproductRefGroup = {ids['products']} /* Products */;")
    add('\t\t\tprojectDirPath = "";')
    add('\t\t\tprojectRoot = "";')
    add("\t\t\ttargets = (")
    add(f"\t\t\t\t{ids['appTarget']} /* LUNE */,")
    add(f"\t\t\t\t{ids['testTarget']} /* LUNETests */,")
    add("\t\t\t);")
    add("\t\t};")
    add("/* End PBXProject section */")
    add("")

    add("/* Begin PBXResourcesBuildPhase section */")
    add(f"\t\t{ids['appResources']} /* Resources */ = {{")
    add("\t\t\tisa = PBXResourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for bid in resource_build_ids:
        add(f"\t\t\t\t{bid} /* resource */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add(f"\t\t{ids['testResources']} /* Resources */ = {{")
    add("\t\t\tisa = PBXResourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXResourcesBuildPhase section */")
    add("")

    add("/* Begin PBXSourcesBuildPhase section */")
    add(f"\t\t{ids['appSources']} /* Sources */ = {{")
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for bid in app_source_ids:
        add(f"\t\t\t\t{bid} /* source */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add(f"\t\t{ids['testSources']} /* Sources */ = {{")
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for bid in test_source_ids:
        add(f"\t\t\t\t{bid} /* test source */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXSourcesBuildPhase section */")
    add("")

    add("/* Begin PBXTargetDependency section */")
    add(f"\t\t{ids['targetDependency']} /* PBXTargetDependency */ = {{")
    add("\t\t\tisa = PBXTargetDependency;")
    add(f"\t\t\ttarget = {ids['appTarget']} /* LUNE */;")
    add(f"\t\t\ttargetProxy = {ids['containerProxy']} /* PBXContainerItemProxy */;")
    add("\t\t};")
    add("/* End PBXTargetDependency section */")
    add("")

    common_project = [
        ("ALWAYS_SEARCH_USER_PATHS", "NO"),
        ("CLANG_ENABLE_MODULES", "YES"),
        ("CLANG_ENABLE_OBJC_ARC", "YES"),
        ("CODE_SIGNING_ALLOWED", "NO"),
        ("CODE_SIGNING_REQUIRED", "NO"),
        ('CODE_SIGN_IDENTITY', '""'),
        ("COPY_PHASE_STRIP", "NO"),
        ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
        ("ENABLE_USER_SCRIPT_SANDBOXING", "YES"),
        ("IPHONEOS_DEPLOYMENT_TARGET", "17.0"),
        ("SDKROOT", "iphoneos"),
        ("SWIFT_VERSION", "5.0"),
    ]

    def emit_config(cid, name, settings, is_debug):
        add(f"\t\t{cid} /* {name} */ = {{")
        add("\t\t\tisa = XCBuildConfiguration;")
        add("\t\t\tbuildSettings = {")
        for key, value in settings:
            add(f"\t\t\t\t{key} = {value};")
        add("\t\t\t};")
        add(f"\t\t\tname = {name};")
        add("\t\t};")

    add("/* Begin XCBuildConfiguration section */")
    emit_config(ids["projectDebug"], "Debug", common_project + [
        ("DEBUG_INFORMATION_FORMAT", "dwarf"),
        ("ENABLE_TESTABILITY", "YES"),
        ("GCC_OPTIMIZATION_LEVEL", "0"),
        ("ONLY_ACTIVE_ARCH", "YES"),
        ("SWIFT_OPTIMIZATION_LEVEL", '"-Onone"'),
    ], True)
    emit_config(ids["projectRelease"], "Release", common_project + [
        ("DEBUG_INFORMATION_FORMAT", '"dwarf-with-dsym"'),
        ("ENABLE_NS_ASSERTIONS", "NO"),
        ("SWIFT_COMPILATION_MODE", "wholemodule"),
        ("VALIDATE_PRODUCT", "YES"),
    ], False)

    app_common = [
        ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
        ("CODE_SIGNING_ALLOWED", "NO"),
        ("CODE_SIGNING_REQUIRED", "NO"),
        ('CODE_SIGN_IDENTITY', '""'),
        ("CODE_SIGN_STYLE", "Manual"),
        ("CURRENT_PROJECT_VERSION", "1"),
        ("DEVELOPMENT_TEAM", '""'),
        ("ENABLE_PREVIEWS", "YES"),
        ("GENERATE_INFOPLIST_FILE", "NO"),
        ("INFOPLIST_FILE", "Info.plist"),
        ('INFOPLIST_KEY_CFBundleDisplayName', '"LUNÉ"'),
        ('INFOPLIST_KEY_UILaunchScreen_Generation', "YES"),
        ("LD_RUNPATH_SEARCH_PATHS", '(\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t)'),
        ("MARKETING_VERSION", "1.0"),
        ("PRODUCT_BUNDLE_IDENTIFIER", "com.lune.cycletracker"),
        ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
        ('PROVISIONING_PROFILE_SPECIFIER', '""'),
        ("SUPPORTED_PLATFORMS", '"iphoneos iphonesimulator"'),
        ("TARGETED_DEVICE_FAMILY", "1"),
        ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ]
    emit_config(ids["appDebug"], "Debug", app_common + [
        ("ENABLE_TESTABILITY", "YES"),
        ("ONLY_ACTIVE_ARCH", "YES"),
    ], True)
    emit_config(ids["appRelease"], "Release", app_common, False)

    test_common = [
        ("CODE_SIGNING_ALLOWED", "NO"),
        ("CODE_SIGNING_REQUIRED", "NO"),
        ('CODE_SIGN_IDENTITY', '""'),
        ("CODE_SIGN_STYLE", "Manual"),
        ("CURRENT_PROJECT_VERSION", "1"),
        ("DEVELOPMENT_TEAM", '""'),
        ("GENERATE_INFOPLIST_FILE", "YES"),
        ("PRODUCT_BUNDLE_IDENTIFIER", "com.lune.cycletracker.tests"),
        ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
        ('PROVISIONING_PROFILE_SPECIFIER', '""'),
        ("SUPPORTED_PLATFORMS", '"iphoneos iphonesimulator"'),
        ("TARGETED_DEVICE_FAMILY", "1"),
        ("SWIFT_VERSION", "5.0"),
        ('TEST_HOST', '"$(BUILT_PRODUCTS_DIR)/LUNE.app/LUNE"'),
        ('BUNDLE_LOADER', '"$(TEST_HOST)"'),
    ]
    emit_config(ids["testDebug"], "Debug", test_common + [("ONLY_ACTIVE_ARCH", "YES")], True)
    emit_config(ids["testRelease"], "Release", test_common, False)
    add("/* End XCBuildConfiguration section */")
    add("")

    add("/* Begin XCConfigurationList section */")
    for cid, configs, label in [
        (ids["projectConfigList"], [ids["projectDebug"], ids["projectRelease"]], "PBXProject"),
        (ids["appConfigList"], [ids["appDebug"], ids["appRelease"]], 'PBXNativeTarget "LUNE"'),
        (ids["testConfigList"], [ids["testDebug"], ids["testRelease"]], 'PBXNativeTarget "LUNETests"'),
    ]:
        add(f"\t\t{cid} /* Build configuration list for {label} */ = {{")
        add("\t\t\tisa = XCConfigurationList;")
        add("\t\t\tbuildConfigurations = (")
        for c in configs:
            add(f"\t\t\t\t{c} /* Debug/Release */,")
        add("\t\t\t);")
        add("\t\t\tdefaultConfigurationIsVisible = 0;")
        add("\t\t\tdefaultConfigurationName = Release;")
        add("\t\t};")
    add("/* End XCConfigurationList section */")
    add("")
    add("\t};")
    add(f"\trootObject = {ids['project']} /* Project object */;")
    add("}")

    PROJECT.mkdir(parents=True, exist_ok=True)
    PBXPROJ.write_text("\n".join(lines) + "\n", encoding="utf-8")

    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['appTarget']}" BuildableName="LUNE.app" BlueprintName="LUNE" ReferencedContainer="container:LUNE.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.PosixSpawn" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['testTarget']}" BuildableName="LUNETests.xctest" BlueprintName="LUNETests" ReferencedContainer="container:LUNE.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.PosixSpawn" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['appTarget']}" BuildableName="LUNE.app" BlueprintName="LUNE" ReferencedContainer="container:LUNE.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['appTarget']}" BuildableName="LUNE.app" BlueprintName="LUNE" ReferencedContainer="container:LUNE.xcodeproj"/>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"/>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
"""
    SCHEME_DIR.mkdir(parents=True, exist_ok=True)
    (SCHEME_DIR / "LUNE.xcscheme").write_text(scheme, encoding="utf-8")
    print(f"Generated {PBXPROJ.relative_to(ROOT)} with {len(app_sources)} app sources, {len(test_sources)} tests, {len(APP_RESOURCES)} resources")


if __name__ == "__main__":
    main()
