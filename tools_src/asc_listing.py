"""Fill the App Store listing for Jigsaw by Pagouro through the App Store Connect API.

Runs in .github/workflows/appstore-listing.yml, where the repo secrets ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_P8 (the
Admin key's PEM text) arrive as environment variables; no key is ever written into the repo or printed.

    python tools_src/asc_listing.py inspect   # read-only: print what App Store Connect has now
    python tools_src/asc_listing.py apply     # create/update the version, attach the build, text, category,
                                              # age rating (all None), review notes and screenshots

It never submits for review, and leaves to Eric what the API cannot do or what is his to say: App Privacy
("Data Not Collected"), Pricing and Availability (Free), the review contact (name, phone, email), content rights,
and the final Add for Review / Submit.
"""
import hashlib
import json
import os
import sys
import time

import jwt
import requests

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://api.appstoreconnect.apple.com"
BUNDLE = "com.pagouro.jigsaw"
L = json.load(open(os.path.join(ROOT, "store", "app_store.json"), encoding="utf-8"))

_tok = {"t": None, "at": 0}


def token():
    if time.time() - _tok["at"] > 600:
        now = int(time.time())
        _tok["t"] = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                               os.environ["ASC_KEY_P8"], algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})
        _tok["at"] = now
    return _tok["t"]


def call(method, path, body=None, ok=(200, 201, 204)):
    r = requests.request(method, API + path, json=body, headers={"Authorization": "Bearer " + token()}, timeout=60)
    if r.status_code not in ok:
        errs = []
        try:
            errs = [(e.get("code"), e.get("detail")) for e in r.json().get("errors", [])]
        except Exception:
            pass
        raise SystemExit("%s %s -> %d %s" % (method, path, r.status_code, errs))
    return r.json() if r.content else {}


def one(path):
    d = call("GET", path)["data"]
    return d[0] if isinstance(d, list) and d else (d or None)


def editable_info(app_id):
    infos = call("GET", "/v1/apps/%s/appInfos" % app_id)["data"]
    for i in infos:
        st = i["attributes"].get("appStoreState") or i["attributes"].get("state")
        if st not in ("READY_FOR_SALE", "READY_FOR_DISTRIBUTION"):
            return i
    return infos[0]


def inspect():
    app = one("/v1/apps?filter[bundleId]=%s" % BUNDLE)
    print("app", app["id"], app["attributes"].get("name"), "contentRights:", app["attributes"].get("contentRightsDeclaration"))
    for v in call("GET", "/v1/apps/%s/appStoreVersions" % app["id"])["data"]:
        a = v["attributes"]
        print("version", v["id"], a.get("platform"), a.get("versionString"), a.get("appStoreState") or a.get("appVersionState"), a.get("releaseType"))
    for b in call("GET", "/v1/builds?filter[app]=%s&sort=-uploadedDate&limit=5" % app["id"])["data"]:
        a = b["attributes"]
        print("build", b["id"], a.get("version"), a.get("processingState"), a.get("uploadedDate"))
    info = editable_info(app["id"])
    print("appInfo", info["id"], info["attributes"])
    ar = one("/v1/appInfos/%s/ageRatingDeclaration" % info["id"])
    if ar:
        print("ageRating", ar["id"], json.dumps(ar["attributes"], sort_keys=True))
    for loc in call("GET", "/v1/appInfos/%s/appInfoLocalizations" % info["id"])["data"]:
        print("infoLoc", loc["attributes"].get("locale"), loc["attributes"].get("name"), loc["attributes"].get("subtitle"))


def find_or_make_version(app_id):
    vs = call("GET", "/v1/apps/%s/appStoreVersions?filter[platform]=IOS" % app_id)["data"]
    attrs = {"versionString": L["version"], "copyright": L["copyright"], "releaseType": L["release_type"]}
    for v in vs:
        st = v["attributes"].get("appStoreState") or v["attributes"].get("appVersionState")
        if st in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"):
            call("PATCH", "/v1/appStoreVersions/" + v["id"], {"data": {"type": "appStoreVersions", "id": v["id"], "attributes": attrs}})
            print("version updated", v["id"], L["version"])
            return v["id"]
    attrs["platform"] = "IOS"
    v = call("POST", "/v1/appStoreVersions", {"data": {"type": "appStoreVersions", "attributes": attrs,
                                                         "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})["data"]
    print("version created", v["id"], L["version"])
    return v["id"]


def upload_screenshot(set_id, path):
    data = open(os.path.join(ROOT, path), "rb").read()
    s = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots",
             "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
             "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
    for op in s["attributes"]["uploadOperations"]:
        part = data[op["offset"]:op["offset"] + op["length"]]
        h = {x["name"]: x["value"] for x in op.get("requestHeaders", [])}
        r = requests.request(op["method"], op["url"], data=part, headers=h, timeout=120)
        if r.status_code >= 300:
            raise SystemExit("screenshot part upload %s -> %d" % (path, r.status_code))
    call("PATCH", "/v1/appScreenshots/" + s["id"], {"data": {"type": "appScreenshots", "id": s["id"],
          "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return s["id"]


def apply():
    app = one("/v1/apps?filter[bundleId]=%s" % BUNDLE)
    app_id = app["id"]
    vid = find_or_make_version(app_id)

    # the build: 0.3.3 (24), once Apple has finished processing it
    builds = call("GET", "/v1/builds?filter[app]=%s&filter[version]=%s&filter[preReleaseVersion.version]=%s"
                  % (app_id, L["build"], L["version"]))["data"]
    if builds and builds[0]["attributes"].get("processingState") == "VALID":
        call("PATCH", "/v1/appStoreVersions/%s/relationships/build" % vid, {"data": {"type": "builds", "id": builds[0]["id"]}})
        print("build attached", L["version"], L["build"])
    else:
        print("BUILD NOT ATTACHED: found", [(b["attributes"].get("version"), b["attributes"].get("processingState")) for b in builds])

    # version text
    locs = call("GET", "/v1/appStoreVersions/%s/appStoreVersionLocalizations" % vid)["data"]
    loc = next((x for x in locs if x["attributes"]["locale"] == "en-US"), locs[0] if locs else None)
    vattrs = {"description": L["description"], "keywords": L["keywords"], "promotionalText": L["promotional_text"],
              "supportUrl": L["support_url"], "marketingUrl": L["marketing_url"]}
    if loc is None:
        loc = call("POST", "/v1/appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations",
                   "attributes": dict(vattrs, locale="en-US"),
                   "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})["data"]
    else:
        call("PATCH", "/v1/appStoreVersionLocalizations/" + loc["id"], {"data": {"type": "appStoreVersionLocalizations",
              "id": loc["id"], "attributes": vattrs}})
    print("version text set", loc["attributes"]["locale"])

    # app info: name, subtitle, privacy URL, category Games > Puzzle
    info = editable_info(app_id)
    call("PATCH", "/v1/appInfos/" + info["id"], {"data": {"type": "appInfos", "id": info["id"], "relationships": {
        "primaryCategory": {"data": {"type": "appCategories", "id": "GAMES"}},
        "primarySubcategoryOne": {"data": {"type": "appCategories", "id": "GAMES_PUZZLE"}}}}})
    print("category Games > Puzzle")
    for il in call("GET", "/v1/appInfos/%s/appInfoLocalizations" % info["id"])["data"]:
        if il["attributes"]["locale"] == "en-US":
            call("PATCH", "/v1/appInfoLocalizations/" + il["id"], {"data": {"type": "appInfoLocalizations", "id": il["id"],
                  "attributes": {"name": L["name"], "subtitle": L["subtitle"], "privacyPolicyUrl": L["privacy_policy_url"]}}})
            print("name, subtitle, privacy URL set")

    # age rating: nothing in any category. Every level field to NONE, every yes/no to false.
    ar = one("/v1/appInfos/%s/ageRatingDeclaration" % info["id"])
    if ar:
        LEVELS = ["alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "gunsOrOtherWeapons",
                  "horrorOrFearThemes", "matureOrSuggestiveThemes", "medicalOrTreatmentInformation",
                  "profanityOrCrudeHumor", "sexualContentGraphicAndNudity", "sexualContentOrNudity",
                  "violenceCartoonOrFantasy", "violenceRealistic", "violenceRealisticProlongedGraphicOrSadistic"]
        FLAGS = ["gambling", "unrestrictedWebAccess", "lootBox", "advertising", "ageAssurance", "healthOrWellnessTopics",
                 "messagingAndChat", "parentalControls", "userGeneratedContent"]
        have = ar["attributes"]
        attrs = {k: "NONE" for k in LEVELS if k in have}
        attrs.update({k: False for k in FLAGS if k in have})
        unknown = sorted(k for k in have if k not in LEVELS and k not in FLAGS)
        try:
            call("PATCH", "/v1/ageRatingDeclarations/" + ar["id"], {"data": {"type": "ageRatingDeclarations", "id": ar["id"], "attributes": attrs}})
            print("age rating: %d fields set to none/false; left for Eric: %s" % (len(attrs), unknown))
        except SystemExit as e:
            print("AGE RATING NOT SET (Eric answers it in the form):", e)
        for k in ("socialMedia", "socialMediaAgeRestricted"):
            if k in have:
                try:
                    call("PATCH", "/v1/ageRatingDeclarations/" + ar["id"], {"data": {"type": "ageRatingDeclarations", "id": ar["id"], "attributes": {k: False}}})
                    print("age rating:", k, "false")
                except SystemExit as e:
                    print("age rating:", k, "left for Eric:", e)

    # review notes (contact name, phone and email are Eric's to enter)
    rd = call("GET", "/v1/appStoreVersions/%s/appStoreReviewDetail" % vid, ok=(200, 404)).get("data")
    rattrs = {"notes": L["review_notes"], "demoAccountRequired": False}
    if rd:
        call("PATCH", "/v1/appStoreReviewDetails/" + rd["id"], {"data": {"type": "appStoreReviewDetails", "id": rd["id"], "attributes": rattrs}})
    else:
        call("POST", "/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": rattrs,
             "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    print("review notes set")

    # screenshots: replace each set's contents with ours
    sets = call("GET", "/v1/appStoreVersionLocalizations/%s/appScreenshotSets" % loc["id"])["data"]
    for kind, files in L["screenshots"].items():
        s = next((x for x in sets if x["attributes"]["screenshotDisplayType"] == kind), None)
        if s is None:
            s = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": kind},
                     "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}})["data"]
        else:
            for old in call("GET", "/v1/appScreenshotSets/%s/appScreenshots" % s["id"])["data"]:
                call("DELETE", "/v1/appScreenshots/" + old["id"])
        ids = [upload_screenshot(s["id"], f) for f in files]
        call("PATCH", "/v1/appScreenshotSets/%s/relationships/appScreenshots" % s["id"],
             {"data": [{"type": "appScreenshots", "id": i} for i in ids]})
        print("screenshots", kind, len(ids))

    # wait for Apple to finish processing the screenshots, and report any it rejected
    time.sleep(20)
    for s in call("GET", "/v1/appStoreVersionLocalizations/%s/appScreenshotSets" % loc["id"])["data"]:
        for sc in call("GET", "/v1/appScreenshotSets/%s/appScreenshots" % s["id"])["data"]:
            st = (sc["attributes"].get("assetDeliveryState") or {})
            print("screenshot", s["attributes"]["screenshotDisplayType"], sc["attributes"].get("fileName"), st.get("state"), st.get("errors") or "")
    print("DONE: not submitted. Left for Eric: App Privacy, Pricing and Availability, review contact, content rights, Submit.")


if __name__ == "__main__":
    {"inspect": inspect, "apply": apply}[sys.argv[1] if len(sys.argv) > 1 else "inspect"]()
