#!/bin/bash
#
# Profile mdviewer with Instruments
# Captures signpost data, Core Animation frames, and CPU usage
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/.build"
APP_NAME="mdviewer"

echo "🔨 Building release version..."
cd "$PROJECT_ROOT"
swift build -c release

APP_PATH="$BUILD_DIR/release/$APP_NAME"

if [ ! -f "$APP_PATH" ]; then
    echo "❌ Error: Built app not found at $APP_PATH"
    exit 1
fi

echo "✅ Build complete: $APP_PATH"
echo ""

# Check if Instruments is available
if ! command -v xcrun &> /dev/null; then
    echo "⚠️  xcrun not found. Make sure Xcode Command Line Tools are installed."
    exit 1
fi

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/ProfileOutput"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TRACE_PATH="$OUTPUT_DIR/mdviewer_profile_$TIMESTAMP.trace"

echo "📊 Available Instruments templates:"
echo "  1) Core Animation (recommended for UI profiling)"
echo "  2) Time Profiler (CPU usage)"
echo "  3) Allocations (memory)"
echo "  4) Signpost (custom signposts)"
echo "  5) Quit"
echo ""

read -p "Select template [1-5]: " choice

case $choice in
    1)
        TEMPLATE="Core Animation"
        echo "🎬 Launching with Core Animation template..."
        echo "   Look for: Frame rate drops during sidebar toggle"
        ;;
    2)
        TEMPLATE="Time Profiler"
        echo "⏱️  Launching with Time Profiler template..."
        echo "   Look for: CPU spikes in body evaluation"
        ;;
    3)
        TEMPLATE="Allocations"
        echo "🧠 Launching with Allocations template..."
        echo "   Look for: Memory growth during repeated renders"
        ;;
    4)
        TEMPLATE="os_signpost"
        echo "📍 Launching with Signpost template..."
        echo "   Look for: InspectorSidebarRender, AsyncMarkdownRender intervals"
        ;;
    5)
        echo "👋 Exiting"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🚀 Starting Instruments..."
echo "   Trace will be saved to: $TRACE_PATH"
echo ""
echo "📋 Signpost intervals to watch:"
echo "   - InspectorSidebarRender (sidebar body evaluation)"
echo "   - AsyncMarkdownRender (markdown parsing)"
echo "   - TextViewUIUpdate (attributed string update)"
echo "   - TextViewCreation (initial text view setup)"
echo ""
echo "📍 Signpost events to watch:"
echo "   - InspectorToggleTapped (toolbar button click)"
echo "   - RenderedModeAppeared / RawModeAppeared (mode switches)"
echo "   - MarkdownRenderCompleted (render pipeline done)"
echo ""
echo "⏺️  Press Cmd+R in Instruments to start recording"
echo "   Interact with the app (toggle sidebar, switch modes)"
echo "   Press Cmd+R again to stop"
echo ""

# Launch Instruments with the selected template
xcrun instruments -t "$TEMPLATE" -D "$TRACE_PATH" "$APP_PATH" &

INSTRUMENTS_PID=$!

echo "🔄 Instruments launched (PID: $INSTRUMENTS_PID)"
echo ""

# Wait for Instruments to launch
sleep 2

# Check if Instruments is still running
if ! kill -0 $INSTRUMENTS_PID 2>/dev/null; then
    echo "⚠️  Instruments may have launched via Xcode instead."
    echo "   Check your Dock for Instruments."
fi

echo "✅ Profiling session started"
echo ""
echo "💡 Tips for profiling:"
echo "   1. Click the sidebar toggle button multiple times"
echo "   2. Switch between Rendered and Raw modes"
echo "   3. Open documents with different sizes"
echo "   4. Watch for dropped frames in Core Animation"
echo ""
echo "📊 When done, save the trace and analyze:"
echo "   - Frame times (should be <16ms for 60fps)"
echo "   - Signpost intervals (measure actual render time)"
echo "   - CPU usage (should drop when idle)"
echo ""

# Keep script running until user quits
read -p "Press Enter to quit this script (Instruments will keep running)..."

echo "👋 Done. Trace saved to: $TRACE_PATH"
