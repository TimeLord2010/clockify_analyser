if ! command -v firebase &> /dev/null; then
  echo ""
  echo "Firebase CLI not found."
  echo ""
  echo "Install it with:"
  echo "  npm install -g firebase-tools"
  echo ""
  echo "Then authenticate:"
  echo "  firebase login"
  echo ""
  exit 1
fi

flutter build web --release || exit -1
firebase deploy