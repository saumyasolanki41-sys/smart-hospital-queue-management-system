import { useState } from "react";
import { Star, X, AlertCircle, CheckCircle2 } from "lucide-react";
import { submitTokenFeedback, getTokenFeedback } from "../../api/queue";

export default function FeedbackModal({
  token,
  isOpen,
  onClose,
  onFeedbackSaved,
  accessToken,
}) {
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [comment, setComment] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [savedFeedback, setSavedFeedback] = useState(token?.feedback || null);

  if (!isOpen) return null;

  async function handleSubmit(e) {
    e.preventDefault();
    if (rating < 1 || rating > 5) {
      setError("Please select a rating from 1 to 5 stars.");
      return;
    }

    setSubmitting(true);
    setError("");

    try {
      const res = await submitTokenFeedback(accessToken, token._id, {
        rating,
        comment: comment.trim() || undefined,
      });
      const fb = res.feedback;
      setSavedFeedback(fb);
      onFeedbackSaved?.(token._id, fb);
    } catch (err) {
      if (err.code === "FEEDBACK_EXISTS") {
        // Feedback already exists, retrieve and display it
        try {
          const res = await getTokenFeedback(accessToken, token._id);
          if (res.feedback) {
            setSavedFeedback(res.feedback);
            onFeedbackSaved?.(token._id, res.feedback);
          }
        } catch {
          // ignore
        }
        setError("Feedback has already been submitted for this consultation.");
      } else if (err.code === "VISIT_NOT_COMPLETED") {
        setError("Feedback can only be submitted for completed consultations.");
      } else {
        setError(err.message || "Failed to submit feedback. Please try again.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  const doctorName = token?.doctor?.name || "Doctor";
  const departmentName = token?.doctor?.department?.name || "";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-100 sm:p-7">
        <button
          type="button"
          onClick={onClose}
          className="absolute right-5 top-5 rounded-full p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors"
          aria-label="Close modal"
        >
          <X className="h-5 w-5" />
        </button>

        <div className="mb-5">
          <span className="inline-block rounded-full bg-cyan-50 px-3 py-1 text-xs font-semibold text-[#197092] border border-cyan-100/80 mb-2">
            Token #{token.tokenNumber}
          </span>
          <h2 className="text-xl font-bold text-slate-900">Consultation Feedback</h2>
          <p className="mt-1 text-sm text-slate-600">
            {doctorName}
            {departmentName ? ` · ${departmentName}` : ""}
          </p>
        </div>

        {savedFeedback ? (
          <div className="rounded-2xl bg-cyan-50/70 border border-cyan-100/80 p-5 text-center">
            <CheckCircle2 className="mx-auto h-8 w-8 text-[#197092] mb-2" />
            <h3 className="font-semibold text-slate-900 text-base">Feedback Received</h3>
            <div className="flex justify-center gap-1 my-3">
              {[1, 2, 3, 4, 5].map((star) => (
                <Star
                  key={star}
                  className={`h-6 w-6 ${
                    star <= savedFeedback.rating
                      ? "fill-amber-400 text-amber-400"
                      : "text-slate-200"
                  }`}
                />
              ))}
            </div>
            {savedFeedback.comment ? (
              <p className="mt-2 text-sm text-slate-700 italic bg-white/80 p-3 rounded-xl border border-cyan-100">
                "{savedFeedback.comment}"
              </p>
            ) : (
              <p className="mt-1 text-xs text-slate-500">No additional comment provided.</p>
            )}
            <p className="mt-3 text-xs text-slate-400">
              Submitted on{" "}
              {new Date(savedFeedback.submittedAt || Date.now()).toLocaleDateString(
                "en-IN",
                { day: "numeric", month: "short", year: "numeric" }
              )}
            </p>
            <button
              type="button"
              onClick={onClose}
              className="mt-5 w-full rounded-xl bg-[#197092] py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-[#145d7a] transition-colors"
            >
              Done
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="flex items-start gap-2 rounded-xl bg-red-50 p-3 text-xs text-red-700 border border-red-200">
                <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Rating <span className="text-red-500">*</span>
              </label>
              <div className="flex items-center gap-2">
                {[1, 2, 3, 4, 5].map((star) => {
                  const filled = star <= (hoverRating || rating);
                  return (
                    <button
                      key={star}
                      type="button"
                      onClick={() => setRating(star)}
                      onMouseEnter={() => setHoverRating(star)}
                      onMouseLeave={() => setHoverRating(0)}
                      className="p-1 rounded-lg hover:scale-110 transition-transform focus:outline-none focus:ring-2 focus:ring-[#197092]/30"
                      aria-label={`${star} star${star > 1 ? "s" : ""}`}
                    >
                      <Star
                        className={`h-8 w-8 transition-colors ${
                          filled
                            ? "fill-amber-400 text-amber-400"
                            : "text-slate-300 hover:text-amber-200"
                        }`}
                      />
                    </button>
                  );
                })}
                {rating > 0 && (
                  <span className="ml-2 text-sm font-medium text-slate-600">
                    {rating} of 5
                  </span>
                )}
              </div>
            </div>

            <div>
              <div className="flex justify-between items-baseline mb-1">
                <label
                  htmlFor="feedback-comment"
                  className="block text-sm font-semibold text-slate-700"
                >
                  Comment <span className="text-xs font-normal text-slate-400">(optional)</span>
                </label>
                <span className="text-xs text-slate-400">{comment.length}/1000</span>
              </div>
              <textarea
                id="feedback-comment"
                rows={3}
                maxLength={1000}
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder="Share your experience (please do not include private medical information)"
                className="w-full rounded-2xl border border-slate-200 p-3 text-sm outline-none transition-all focus:border-[#197092] focus:ring-2 focus:ring-cyan-500/20"
              />
            </div>

            <div className="rounded-xl bg-slate-50 p-3 text-xs text-slate-500 border border-slate-200/60">
              <span className="font-semibold text-slate-700">Notice:</span> Feedback is final and cannot be edited or deleted once submitted. Comments are private.
            </div>

            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={onClose}
                disabled={submitting}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitting || rating === 0}
                className="flex-1 rounded-xl bg-[#197092] py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-[#145d7a] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {submitting ? "Submitting…" : "Submit Feedback"}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
