/* //device/java/android/android/view/IWindowSession.aidl
**
** Copyright 2006, The Android Open Source Project
**
** Licensed under the Apache License, Version 2.0 (the "License"); 
** you may not use this file except in compliance with the License. 
** You may obtain a copy of the License at 
**
**     http://www.apache.org/licenses/LICENSE-2.0 
**
** Unless required by applicable law or agreed to in writing, software 
** distributed under the License is distributed on an "AS IS" BASIS, 
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
** See the License for the specific language governing permissions and 
** limitations under the License.
*/

package android.view;

import android.content.ClipData;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.graphics.Region;
import android.os.Bundle;
import android.view.InputChannel;
import android.view.IWindow;
import android.view.IWindowId;
import android.view.MotionEvent;
import android.view.WindowManager;
import android.view.Surface;

/**
 * System private per-application interface to the window manager.
 *
 * {@hide}
 */
interface IWindowSession {
    int add(IWindow window, int seq, in WindowManager.LayoutParams attrs,
            in int viewVisibility, out Rect outContentInsets, out Rect outStableInsets,
            out InputChannel outInputChannel);
    int addToDisplay(IWindow window, int seq, in WindowManager.LayoutParams attrs,
            in int viewVisibility, in int layerStackId, out Rect outContentInsets,
            out Rect outStableInsets, out Rect outOutsets, out InputChannel outInputChannel);
    int addWithoutInputChannel(IWindow window, int seq, in WindowManager.LayoutParams attrs,
            in int viewVisibility, out Rect outContentInsets, out Rect outStableInsets);
    int addToDisplayWithoutInputChannel(IWindow window, int seq, in WindowManager.LayoutParams attrs,
            in int viewVisibility, in int layerStackId, out Rect outContentInsets,
            out Rect outStableInsets);
    void remove(IWindow window);

    /**
     * Change the parameters of a window.  You supply the
     * new parameters, it returns the new frame of the window on screen (the
     * position should be ignored) and surface of the window.  The surface
     * will be invalid if the window is currently hidden, else you can use it
     * to draw the window's contents.
     * 
     * @param window The window being modified.
     * @param seq Ordering sequence number.
     * @param attrs If non-null, new attributes to apply to the window.
     * @param requestedWidth The width the window wants to be.
     * @param requestedHeight The height the window wants to be.
     * @param viewVisibility Window root view's visibility.
     * @param flags Request flags: {@link WindowManagerGlobal#RELAYOUT_INSETS_PENDING},
     * {@link WindowManagerGlobal#RELAYOUT_DEFER_SURFACE_DESTROY}.
     * @param outFrame Rect in which is placed the new position/size on
     * screen.
     * @param outOverscanInsets Rect in which is placed the offsets from
     * <var>outFrame</var> in which the content of the window are inside
     * of the display's overlay region.
     * @param outContentInsets Rect in which is placed the offsets from
     * <var>outFrame</var> in which the content of the window should be
     * placed.  This can be used to modify the window layout to ensure its
     * contents are visible to the user, taking into account system windows
     * like the status bar or a soft keyboard.
     * @param outVisibleInsets Rect in which is placed the offsets from
     * <var>outFrame</var> in which the window is actually completely visible
     * to the user.  This can be used to temporarily scroll the window's
     * contents to make sure the user can see it.  This is different than
     * <var>outContentInsets</var> in that these insets change transiently,
     * so complex relayout of the window should not happen based on them.
     * @param outOutsets Rect in which is placed the dead area of the screen that we would like to
     * treat as real display. Example of such area is a chin in some models of wearable devices.
     * @param outBackdropFrame Rect which is used draw the resizing background during a resize
     * operation.
     * @param outConfiguration New configuration of window, if it is now
     * becoming visible and the global configuration has changed since it
     * was last displayed.
     * @param outSurface Object in which is placed the new display surface.
     *
     * @return int Result flags: {@link WindowManagerGlobal#RELAYOUT_SHOW_FOCUS},
     * {@link WindowManagerGlobal#RELAYOUT_FIRST_TIME}.
     */
    int relayout(IWindow window, int seq, in WindowManager.LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewVisibility,
            int flags, out Rect outFrame, out Rect outOverscanInsets,
            out Rect outContentInsets, out Rect outVisibleInsets, out Rect outStableInsets,
            out Rect outOutsets, out Rect outBackdropFrame, out Configuration outConfig,
            out Surface outSurface);

    /**
     *  Position a window relative to it's parent (attached) window without triggering
     *  a full relayout. This action may be deferred until a given frame number
     *  for the parent window appears. This allows for synchronizing movement of a child
     *  to repainting the contents of the parent.
     *
     *  "width" and "height" correspond to the width and height members of
     *  WindowManager.LayoutParams in the {@link #relayout relayout()} case.
     *  This may differ from the surface buffer size in the
     *  case of {@link LayoutParams#FLAG_SCALED} and {@link #relayout relayout()}
     *  must be used with requestedWidth/height if this must be changed.
     *
     *  @param window The window being modified. Must be attached to a parent window
     *  or this call will fail.
     *  @param left The new left position
     *  @param top The new top position
     *  @param right The new right position
     *  @param bottom The new bottom position
     *  @param deferTransactionUntilFrame Frame number from our parent (attached) to
     *  defer this action until.
     *  @param outFrame Rect in which is placed the new position/size on screen.
     */
    void repositionChild(IWindow childWindow, int left, int top, int right, int bottom,
            long deferTransactionUntilFrame, out Rect outFrame);

    /*
     * Notify the window manager that an application is relaunching and
     * windows should be prepared for replacement.
     *
     * @param appToken The application
     * @param childrenOnly Whether to only prepare child windows for replacement
     * (for example when main windows are being reused via preservation).
     */
    void prepareToReplaceWindows(IBinder appToken, boolean childrenOnly);

    /**
     * If a call to relayout() asked to have the surface destroy deferred,
     * it must call this once it is okay to destroy that surface.
     */
    void performDeferredDestroy(IWindow window);

    /**
     * Called by a client to report that it ran out of graphics memory.
     */
    boolean outOfMemory(IWindow window);

    /**
     * Give the window manager a hint of the part of the window that is
     * completely transparent, allowing it to work with the surface flinger
     * to optimize compositing of this part of the window.
     */
    void setTransparentRegion(IWindow window, in Region region);

    /**
     * Tell the window manager about the content and visible insets of the
     * given window, which can be used to adjust the <var>outContentInsets</var>
     * and <var>outVisibleInsets</var> values returned by
     * {@link #relayout relayout()} for windows behind this one.
     *
     * @param touchableInsets Controls which part of the window inside of its
     * frame can receive pointer events, as defined by
     * {@link android.view.ViewTreeObserver.InternalInsetsInfo}.
     */
    void setInsets(IWindow window, int touchableInsets, in Rect contentInsets,
            in Rect visibleInsets, in Region touchableRegion);

    /**
     * Return the current display size in which the window is being laid out,
     * accounting for screen decorations around it.
     */
    void getDisplayFrame(IWindow window, out Rect outDisplayFrame);

    void finishDrawing(IWindow window);

    void setInTouchMode(boolean showFocus);
    boolean getInTouchMode();

    boolean performHapticFeedback(IWindow window, int effectId, boolean always);

    /**
     * Allocate the drag's thumbnail surface.  Also assigns a token that identifies
     * the drag to the OS and passes that as the return value.  A return value of
     * null indicates failure.
     */
    IBinder prepareDrag(IWindow window, int flags,
            int thumbnailWidth, int thumbnailHeight, out Surface outSurface);

    /**
     * Initiate the drag operation itself
     */
    boolean performDrag(IWindow window, IBinder dragToken, int touchSource,
            float touchX, float touchY, float thumbCenterX, float thumbCenterY, in ClipData data);

   /**
     * Report the result of a drop action targeted to the given window.
     * consumed is 'true' when the drop was accepted by a valid recipient,
     * 'false' otherwise.
     */
	void reportDropResult(IWindow window, boolean consumed);

    /**
     * Cancel the current drag operation.
     */
    void cancelDragAndDrop(IBinder dragToken);

    /**
     * Tell the OS that we've just dragged into a View that is willing to accept the drop
     */
    void dragRecipientEntered(IWindow window);

    /**
     * Tell the OS that we've just dragged *off* of a View that was willing to accept the drop
     */
    void dragRecipientExited(IWindow window);

    /**
     * For windows with the wallpaper behind them, and the wallpaper is
     * larger than the screen, set the offset within the screen.
     * For multi screen launcher type applications, xstep and ystep indicate
     * how big the increment is from one screen to another.
     */
    void setWallpaperPosition(IBinder windowToken, float x, float y, float xstep, float ystep);

    void wallpaperOffsetsComplete(IBinder window);

    /**
     * Apply a raw offset to the wallpaper service when shown behind this window.
     */
    void setWallpaperDisplayOffset(IBinder windowToken, int x, int y);

    Bundle sendWallpaperCommand(IBinder window, String action, int x, int y,
            int z, in Bundle extras, boolean sync);

    void wallpaperCommandComplete(IBinder window, in Bundle result);

    /**
     * Notifies that a rectangle on the screen has been requested.
     */
    void onRectangleOnScreenRequested(IBinder token, in Rect rectangle);

    IWindowId getWindowId(IBinder window);

    /**
     * When the system is dozing in a low-power partially suspended state, pokes a short
     * lived wake lock and ensures that the display is ready to accept the next frame
     * of content drawn in the window.
     *
     * This mechanism is bound to the window rather than to the display manager or the
     * power manager so that the system can ensure that the window is actually visible
     * and prevent runaway applications from draining the battery.  This is similar to how
     * FLAG_KEEP_SCREEN_ON works.
     *
     * This method is synchronous because it may need to acquire a wake lock before returning.
     * The assumption is that this method will be called rather infrequently.
     */
    void pokeDrawLock(IBinder window);

    /**
     * Starts a task window move with {startX, startY} as starting point. The amount of move
     * will be the offset between {startX, startY} and the new cursor position.
     *
     * Returns true if the move started successfully; false otherwise.
     */
    boolean startMovingTask(IWindow window, float startX, float startY);

    void updatePointerIcon(IWindow window);

    
    void hideWindowLayer(IWindow window, boolean visible);
    void updatePositionAndSize(IWindow window,int x,int y,int widht,int height);
}
