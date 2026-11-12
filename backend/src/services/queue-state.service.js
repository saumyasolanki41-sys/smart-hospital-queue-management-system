function queueState(doctor) {
  return {
    paused: doctor?.queuePaused === true,
    reason: doctor?.queuePaused === true ? doctor.queuePauseReason || 'break' : null,
    pausedAt: doctor?.queuePaused === true ? doctor.queuePausedAt || null : null,
  };
}

module.exports = queueState;
