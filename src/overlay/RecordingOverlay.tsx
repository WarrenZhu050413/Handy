import { listen } from "@tauri-apps/api/event";
import React, { useEffect, useRef, useState } from "react";
import {
  MicrophoneIcon,
  TranscriptionIcon,
  CancelIcon,
} from "../components/icons";
import "./RecordingOverlay.css";
import { commands } from "@/bindings";

type OverlayState = "recording" | "transcribing";

const RecordingOverlay: React.FC = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [state, setState] = useState<OverlayState>("recording");
  const [levels, setLevels] = useState<number[]>(Array(16).fill(0));
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const smoothedLevelsRef = useRef<number[]>(Array(16).fill(0));
  const timerRef = useRef<number | null>(null);

  useEffect(() => {
    const setupEventListeners = async () => {
      // Listen for show-overlay event from Rust
      const unlistenShow = await listen("show-overlay", (event) => {
        const overlayState = event.payload as OverlayState;
        setState(overlayState);
        setIsVisible(true);

        // Start timer when recording begins
        if (overlayState === "recording") {
          setElapsedSeconds(0);
          if (timerRef.current) {
            clearInterval(timerRef.current);
          }
          timerRef.current = window.setInterval(() => {
            setElapsedSeconds((prev) => prev + 1);
          }, 1000);
        } else {
          // Stop timer when transcribing
          if (timerRef.current) {
            clearInterval(timerRef.current);
            timerRef.current = null;
          }
        }
      });

      // Listen for hide-overlay event from Rust
      const unlistenHide = await listen("hide-overlay", () => {
        setIsVisible(false);
        // Stop timer when overlay hides
        if (timerRef.current) {
          clearInterval(timerRef.current);
          timerRef.current = null;
        }
      });

      // Listen for mic-level updates
      const unlistenLevel = await listen<number[]>("mic-level", (event) => {
        const newLevels = event.payload as number[];

        // Apply smoothing to reduce jitter
        const smoothed = smoothedLevelsRef.current.map((prev, i) => {
          const target = newLevels[i] || 0;
          return prev * 0.7 + target * 0.3; // Smooth transition
        });

        smoothedLevelsRef.current = smoothed;
        setLevels(smoothed.slice(0, 9));
      });

      // Cleanup function
      return () => {
        unlistenShow();
        unlistenHide();
        unlistenLevel();
        if (timerRef.current) {
          clearInterval(timerRef.current);
        }
      };
    };

    setupEventListeners();
  }, []);

  // Format seconds as "Xs" or "M:SS" for longer durations
  const formatTime = (seconds: number): string => {
    if (seconds < 60) {
      return `${seconds}s`;
    }
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  const getIcon = () => {
    if (state === "recording") {
      return <MicrophoneIcon />;
    } else {
      return <TranscriptionIcon />;
    }
  };

  return (
    <div className={`recording-overlay ${isVisible ? "fade-in" : ""}`}>
      <div className="overlay-left">{getIcon()}</div>

      <div className="overlay-middle">
        {state === "recording" && (
          <div className="bars-container">
            {levels.map((v, i) => (
              <div
                key={i}
                className="bar"
                style={{
                  height: `${Math.min(20, 4 + Math.pow(v, 0.7) * 16)}px`, // Cap at 20px max height
                  transition: "height 60ms ease-out, opacity 120ms ease-out",
                  opacity: Math.max(0.2, v * 1.7), // Minimum opacity for visibility
                }}
              />
            ))}
          </div>
        )}
        {state === "transcribing" && (
          <div className="transcribing-text">Transcribing...</div>
        )}
      </div>

      <div className="overlay-right">
        {state === "recording" && (
          <>
            <span className="elapsed-time">{formatTime(elapsedSeconds)}</span>
            <div
              className="cancel-button"
              onClick={() => {
                commands.cancelOperation();
              }}
            >
              <CancelIcon />
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default RecordingOverlay;
