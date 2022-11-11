package com.magugi.volume_watcher;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.util.Log;

import java.lang.ref.WeakReference;

/**
 * System volume monitoring
 */
public class VolumeChangeObserver {
    public final static String TAG = "volume_watcher";
    private static final String VOLUME_CHANGED_ACTION = "android.media.VOLUME_CHANGED_ACTION";
    private static final String EXTRA_VOLUME_STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE";

    private VolumeChangeListener mVolumeChangeListener;
    private VolumeBroadcastReceiver mVolumeBroadcastReceiver;
    private Context mContext;
    private AudioManager mAudioManager;
    private boolean mRegistered = false;
    // Maximum volume
    private double mMaxVolume;

    public interface VolumeChangeListener {
        /**
         * System media volume changes
         *
         * @param volume
         */
        void onVolumeChanged(double volume);
    }

    public VolumeChangeObserver(Context context) {
        mContext = context;
        mAudioManager = (AudioManager) context.getApplicationContext().getSystemService(Context.AUDIO_SERVICE);
        mMaxVolume = mAudioManager != null ? mAudioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC) : 15;
    }

    /**
     * Get the current media volume
     *
     * @return
     */
    public double getCurrentMusicVolume() {
        int currentVolume = mAudioManager != null ? mAudioManager.getStreamVolume(AudioManager.STREAM_MUSIC) : -1;
        return currentVolume / mMaxVolume;
    }

    /**
     * Get the maximum media volume of the system
     *
     * @return
     */
    public double getMaxMusicVolume() {
        return 1.0d;
    }

    /**
     * Set the volume
     * @param value
     */
    public void setVolume(double value){
        double actualValue;
        if (value > 1.0) {
            actualValue = 1.0;
        } else if (value < 0.0) {
            actualValue = 0.0;
        } else {
            actualValue = value;
        }

        int volume = (int)Math.round(actualValue * mMaxVolume);
        if(mAudioManager != null){
            try{
                // Set the volume
                mAudioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0);
                if(volume<1){
                    mAudioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_LOWER,  0);
                }
            }catch (Exception ex){
                // Print log
                Log.d(TAG, "setVolume Exception:" + ex.getMessage());
            }
        }
    }

    public VolumeChangeListener getVolumeChangeListener() {
        return mVolumeChangeListener;
    }

    public void setVolumeChangeListener(VolumeChangeListener volumeChangeListener) {
        this.mVolumeChangeListener = volumeChangeListener;
    }

    /**
     * Registration volume Broadcast receiver
     *
     * @return
     */
    public void registerReceiver() {
        mVolumeBroadcastReceiver = new VolumeBroadcastReceiver(this);
        IntentFilter filter = new IntentFilter();
        filter.addAction(VOLUME_CHANGED_ACTION);
        mContext.registerReceiver(mVolumeBroadcastReceiver, filter);
        mRegistered = true;
    }

    /**
     * The registered volume Broadcasting monitor needs to be used in pairs with the registerReceiver
     */
    public void unregisterReceiver() {
        if (mRegistered) {
            try {
                mContext.unregisterReceiver(mVolumeBroadcastReceiver);
                mVolumeChangeListener = null;
                mRegistered = false;
            } catch (Exception e) {
                Log.e(TAG, "unregisterReceiver: ", e);
            }
        }
    }

    // Change of listening volume changes
    private static class VolumeBroadcastReceiver extends BroadcastReceiver {
        private WeakReference<VolumeChangeObserver> mObserverWeakReference;

        public VolumeBroadcastReceiver(VolumeChangeObserver volumeChangeObserver) {
            mObserverWeakReference = new WeakReference<>(volumeChangeObserver);
        }

        @Override
        public void onReceive(Context context, Intent intent) {
            // The media volume change is not notified
            if (VOLUME_CHANGED_ACTION.equals(intent.getAction()) && (intent.getIntExtra(EXTRA_VOLUME_STREAM_TYPE, -1) == AudioManager.STREAM_MUSIC)) {
                VolumeChangeObserver observer = mObserverWeakReference.get();
                if (observer != null) {
                    VolumeChangeListener listener = observer.getVolumeChangeListener();
                    if (listener != null) {
                        double volume = observer.getCurrentMusicVolume();
                        if (volume >= 0) {
                            listener.onVolumeChanged(volume);
                        }
                    }
                }
            }

        }
    }

}
