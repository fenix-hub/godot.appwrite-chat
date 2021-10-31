# web
python -m http.server 8000

# android
adb connect localhost:58526
adb reverse tcp:7000 tcp:7000
adb logcat pidof 'org.godotengine.appwritesdk' -s *:D

