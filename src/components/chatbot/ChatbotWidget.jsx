import { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import {
  MessageSquare,
  X,
  Send,
  RotateCcw,
  Sparkles,
  Bot,
  User,
  AlertCircle,
  ChevronDown,
  LogIn,
  CheckCircle2,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { sendChatMessage } from "../../api/chatbot";

const CHAT_STORAGE_KEY = "smart_hospital_chat_history";
const SESSION_STORAGE_KEY = "smart_hospital_chat_session_id";

const DEFAULT_SUGGESTIONS = [
  "Show departments",
  "Available doctors",
  "My tokens",
  "Emergency ambulance",
];

function formatMessageText(text) {
  if (!text) return "";
  const lines = text.split("\n");

  return lines.map((line, idx) => {
    const isBullet = line.trim().startsWith("- ") || line.trim().startsWith("* ");
    const isNumbered = /^\s*\d+\.\s+/.test(line);

    const parts = line.split(/(\*\*[^*]+\*\*)/g).map((part, pIdx) => {
      if (part.startsWith("**") && part.endsWith("**")) {
        return <strong key={pIdx} className="font-semibold">{part.slice(2, -2)}</strong>;
      }
      return part;
    });

    if (isBullet) {
      return (
        <li key={idx} className="ml-4 list-disc pl-1 text-inherit">
          {parts.slice(1).length > 0 ? parts : line.replace(/^[-*]\s+/, "")}
        </li>
      );
    }

    if (isNumbered) {
      return (
        <li key={idx} className="ml-4 list-decimal pl-1 text-inherit">
          {parts}
        </li>
      );
    }

    if (line.trim() === "") {
      return <div key={idx} className="h-2" />;
    }

    return (
      <p key={idx} className="min-h-[1.25rem]">
        {parts}
      </p>
    );
  });
}

export default function ChatbotWidget() {
  const { user, token: accessToken } = useAuth();

  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState(() => {
    try {
      const saved = sessionStorage.getItem(CHAT_STORAGE_KEY);
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  const [sessionId, setSessionId] = useState(() => {
    try {
      return sessionStorage.getItem(SESSION_STORAGE_KEY) || null;
    } catch {
      return null;
    }
  });

  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [lastFailedMessage, setLastFailedMessage] = useState(null);

  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);
  const prevUserRef = useRef(user?._id || null);

  useEffect(() => {
    const currentUserId = user?._id || null;
    if (prevUserRef.current && !currentUserId) {
      handleNewConversation();
    }
    prevUserRef.current = currentUserId;
  }, [user]);

  useEffect(() => {
    try {
      if (messages.length > 0) {
        sessionStorage.setItem(CHAT_STORAGE_KEY, JSON.stringify(messages));
      } else {
        sessionStorage.removeItem(CHAT_STORAGE_KEY);
      }
    } catch {
    }
  }, [messages]);

  useEffect(() => {
    try {
      if (sessionId) {
        sessionStorage.setItem(SESSION_STORAGE_KEY, sessionId);
      } else {
        sessionStorage.removeItem(SESSION_STORAGE_KEY);
      }
    } catch {
    }
  }, [sessionId]);

  useEffect(() => {
    if (isOpen) {
      messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, loading, isOpen]);

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => {
        inputRef.current?.focus();
      }, 150);
    }
  }, [isOpen]);

  useEffect(() => {
    function handleOpenEvent(e) {
      setIsOpen(true);
      if (e.detail?.prompt) {
        handleSend(e.detail.prompt);
      }
    }
    window.addEventListener("open-hospital-chatbot", handleOpenEvent);
    return () => window.removeEventListener("open-hospital-chatbot", handleOpenEvent);
  }, []);

  function handleNewConversation() {
    setMessages([]);
    setSessionId(null);
    setError("");
    setLastFailedMessage(null);
    try {
      sessionStorage.removeItem(CHAT_STORAGE_KEY);
      sessionStorage.removeItem(SESSION_STORAGE_KEY);
    } catch {
    }
  }

  async function handleSend(customText) {
    const textToSend = (customText || input).trim();
    if (!textToSend || loading) return;

    setError("");
    setLastFailedMessage(null);
    if (!customText) {
      setInput("");
    }

    const userMsg = {
      id: `user-${Date.now()}`,
      sender: "user",
      text: textToSend,
      time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
    };

    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);

    try {
      const response = await sendChatMessage({
        message: textToSend,
        sessionId,
        accessToken,
        mode: "auto",
      });

      if (response.session_id) {
        setSessionId(response.session_id);
      }

      const botMsg = {
        id: `bot-${Date.now()}`,
        sender: "bot",
        text: response.reply,
        intent: response.intent,
        suggestions: response.suggestions || [],
        source: response.source,
        time: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      };

      setMessages((prev) => [...prev, botMsg]);
    } catch (err) {
      setError(err.message || "Failed to reach the assistant.");
      setLastFailedMessage(textToSend);
    } finally {
      setLoading(false);
    }
  }

  function handleKeyDown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  }

  const lastBotMessage = [...messages].reverse().find((m) => m.sender === "bot");
  const currentSuggestions =
    lastBotMessage && lastBotMessage.suggestions?.length > 0
      ? lastBotMessage.suggestions
      : messages.length === 0
      ? DEFAULT_SUGGESTIONS
      : [];

  return (
    <>
      {/* Floating launcher button */}
      <div className="fixed bottom-6 right-6 z-40 flex flex-col items-end">
        {!isOpen && (
          <button
            type="button"
            onClick={() => setIsOpen(true)}
            aria-label="Open Hospital Assistant"
            className="group flex items-center gap-2.5 rounded-full bg-gradient-to-r from-[#197092] to-[#0c4764] px-4 py-3.5 text-white shadow-xl shadow-cyan-950/25 hover:shadow-2xl hover:scale-105 active:scale-95 transition-all duration-200 border border-white/20"
          >
            <div className="relative flex items-center justify-center">
              <Bot className="h-6 w-6 text-white" />
              <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-cyan-300" />
              </span>
            </div>
            <span className="text-sm font-semibold tracking-wide">
              Ask AI Assistant
            </span>
          </button>
        )}
      </div>

      {/* Chat Window */}
      {isOpen && (
        <div className="fixed inset-x-4 bottom-4 sm:inset-x-auto sm:right-6 sm:bottom-6 sm:w-[420px] h-[600px] max-h-[85vh] z-50 flex flex-col rounded-3xl bg-white/95 backdrop-blur-xl border border-cyan-100 shadow-2xl shadow-cyan-950/30 overflow-hidden animate-in fade-in slide-in-from-bottom-5 duration-200">
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 bg-gradient-to-r from-[#0a3d54] via-[#0c4764] to-[#197092] text-white">
            <div className="flex items-center gap-3">
              <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cyan-200 border border-white/20 shadow-inner">
                <Bot className="h-5 w-5" />
                <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-emerald-400 border-2 border-[#0a3d54]" />
              </div>
              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="font-bold text-sm tracking-wide">Hospital Assistant</h3>
                  <span className="rounded-full bg-cyan-400/20 px-2 py-0.5 text-[10px] font-semibold text-cyan-200 uppercase tracking-wider">
                    AI Live
                  </span>
                </div>
                <p className="text-[11px] text-cyan-100/75 flex items-center gap-1">
                  <span>Queues, Doctors &amp; Hospital Care</span>
                  {user && (
                    <>
                      <span>•</span>
                      <span className="text-cyan-200 font-medium">
                        {user.name?.split(" ")[0]}
                      </span>
                    </>
                  )}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-1 text-cyan-100">
              <button
                type="button"
                onClick={handleNewConversation}
                title="Start New Conversation"
                className="rounded-xl p-2 hover:bg-white/10 hover:text-white transition-colors"
                aria-label="Start new conversation"
              >
                <RotateCcw className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => setIsOpen(false)}
                title="Close Assistant"
                className="rounded-xl p-2 hover:bg-white/10 hover:text-white transition-colors"
                aria-label="Close assistant"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Messages scroll area */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gradient-to-b from-cyan-50/30 to-white/60">
            {/* Welcome banner when empty */}
            {messages.length === 0 && (
              <div className="rounded-2xl bg-cyan-50/80 border border-cyan-100/80 p-4 text-center my-2">
                <div className="mx-auto flex h-11 w-11 items-center justify-center rounded-2xl bg-[#197092] text-white shadow-md shadow-cyan-950/15 mb-2.5">
                  <Sparkles className="h-5 w-5" />
                </div>
                <h4 className="text-sm font-bold text-slate-800">
                  Welcome to Smart Hospital!
                </h4>
                <p className="mt-1 text-xs text-slate-600 leading-relaxed">
                  I can assist you with department directories, doctor availability, queue updates, and bookings.
                </p>
                {!user && (
                  <p className="mt-2 text-[11px] text-slate-500 bg-white/70 py-1.5 px-3 rounded-xl border border-slate-200/60 inline-block">
                    Tip: <Link to="/login" onClick={() => setIsOpen(false)} className="text-[#197092] font-semibold underline">Log in</Link> to view and manage personal tokens.
                  </p>
                )}
              </div>
            )}

            {/* Render message bubbles */}
            {messages.map((msg) => {
              const isUser = msg.sender === "user";

              return (
                <div
                  key={msg.id}
                  className={`flex flex-col ${isUser ? "items-end" : "items-start"}`}
                >
                  <div className="flex items-end gap-2 max-w-[85%]">
                    {!isUser && (
                      <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-xl bg-cyan-100 text-[#197092] text-xs font-bold mb-1 shadow-xs">
                        <Bot className="h-4 w-4" />
                      </div>
                    )}

                    <div
                      className={`rounded-2xl p-3.5 text-xs sm:text-sm leading-relaxed ${
                        isUser
                          ? "bg-gradient-to-br from-[#197092] to-[#0c4764] text-white rounded-br-xs shadow-md shadow-cyan-950/15"
                          : "bg-white text-slate-800 border border-cyan-100/90 rounded-bl-xs shadow-sm"
                      }`}
                    >
                      <div className="space-y-1">{formatMessageText(msg.text)}</div>

                      {/* If login is required, show a login CTA button */}
                      {msg.intent === "login_required" && !user && (
                        <div className="mt-3 pt-2.5 border-t border-slate-100">
                          <Link
                            to="/login"
                            onClick={() => setIsOpen(false)}
                            className="inline-flex items-center gap-1.5 rounded-xl bg-[#197092] px-3.5 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-[#145d7a] transition-colors"
                          >
                            <LogIn className="h-3.5 w-3.5" />
                            <span>Log in to your account</span>
                          </Link>
                        </div>
                      )}

                      {/* Source tag if present */}
                      {!isUser && msg.source && (
                        <div className="mt-2 flex items-center justify-end gap-1.5 text-[10px] text-slate-400">
                          <span>source: {msg.source}</span>
                        </div>
                      )}
                    </div>

                    {isUser && (
                      <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-xl bg-slate-200 text-slate-700 text-xs font-bold mb-1 shadow-xs">
                        <User className="h-4 w-4" />
                      </div>
                    )}
                  </div>

                  <span className="mt-1 px-9 text-[10px] text-slate-400">
                    {msg.time}
                  </span>
                </div>
              );
            })}

            {/* Loading indicator */}
            {loading && (
              <div className="flex items-end gap-2 max-w-[85%]">
                <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-xl bg-cyan-100 text-[#197092] text-xs font-bold mb-1">
                  <Bot className="h-4 w-4" />
                </div>
                <div className="rounded-2xl rounded-bl-xs bg-white border border-cyan-100 p-3.5 shadow-sm text-xs text-slate-500 flex items-center gap-2">
                  <span className="flex items-center gap-1">
                    <span className="h-2 w-2 rounded-full bg-[#197092] animate-bounce [animation-delay:-0.3s]" />
                    <span className="h-2 w-2 rounded-full bg-[#197092] animate-bounce [animation-delay:-0.15s]" />
                    <span className="h-2 w-2 rounded-full bg-[#197092] animate-bounce" />
                  </span>
                  <span>Assistant is thinking…</span>
                </div>
              </div>
            )}

            {/* Error display */}
            {error && (
              <div className="rounded-2xl bg-red-50 border border-red-200 p-3 text-xs text-red-700 flex items-start justify-between gap-2">
                <div className="flex items-start gap-2">
                  <AlertCircle className="h-4 w-4 shrink-0 mt-0.5 text-red-600" />
                  <span>{error}</span>
                </div>
                {lastFailedMessage && (
                  <button
                    type="button"
                    onClick={() => handleSend(lastFailedMessage)}
                    className="shrink-0 font-semibold underline hover:text-red-900"
                  >
                    Retry
                  </button>
                )}
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Suggestions Pill Bar */}
          {currentSuggestions.length > 0 && !loading && (
            <div className="px-4 py-2 border-t border-slate-100 bg-white/90">
              <p className="text-[10px] uppercase font-bold tracking-wider text-slate-400 mb-1.5 flex items-center gap-1">
                <Sparkles className="h-3 w-3 text-[#197092]" />
                <span>Suggestions</span>
              </p>
              <div className="flex flex-wrap gap-1.5 max-h-20 overflow-y-auto">
                {currentSuggestions.map((suggestion, sIdx) => (
                  <button
                    key={sIdx}
                    type="button"
                    onClick={() => handleSend(suggestion)}
                    className="rounded-full bg-cyan-50 hover:bg-[#197092] hover:text-white border border-cyan-200/80 px-3 py-1 text-xs font-medium text-[#197092] transition-colors shadow-2xs active:scale-95"
                  >
                    {suggestion}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Input field */}
          <div className="p-3 bg-white border-t border-slate-100">
            <div className="relative flex items-center">
              <input
                ref={inputRef}
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Ask about departments, doctors, tokens…"
                disabled={loading}
                className="w-full rounded-2xl border border-slate-200/80 bg-slate-50/60 py-3 pl-4 pr-12 text-xs sm:text-sm text-slate-800 placeholder-slate-400 outline-none transition-all focus:border-[#197092] focus:bg-white focus:ring-4 focus:ring-cyan-500/10 disabled:opacity-60"
              />
              <button
                type="button"
                onClick={() => handleSend()}
                disabled={!input.trim() || loading}
                aria-label="Send message"
                className="absolute right-2 flex h-8 w-8 items-center justify-center rounded-xl bg-[#197092] text-white shadow-sm transition-all hover:bg-[#145d7a] disabled:opacity-40 disabled:cursor-not-allowed active:scale-95"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
            <div className="mt-1 flex items-center justify-between px-1">
              <span className="text-[10px] text-slate-400">
                Press Enter to send
              </span>
              {sessionId && (
                <button
                  type="button"
                  onClick={handleNewConversation}
                  className="text-[10px] text-slate-400 hover:text-[#197092] hover:underline"
                >
                  Clear conversation
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
