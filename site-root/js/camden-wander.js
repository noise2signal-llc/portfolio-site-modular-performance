var hls = null;
const player = document.getElementById('player');
var playerInterface = document.getElementById('playerInterface');
var mainControl = document.getElementById('mainControl');
var timeline = document.getElementById('timeline');
var timelinePlayed = document.getElementById('timeline-played');
var timelinePlayedStatus = document.getElementById('played-status');
var timelineQueuedStatus = document.getElementById('queued-status');

var currentTrackData = null;
var loadedTrack = null;

function formatTime(seconds) {
  if (isNaN(seconds) || !isFinite(seconds)) return '0:00';
  var mins = Math.floor(seconds / 60);
  var secs = Math.floor(seconds % 60);
  return mins + ':' + (secs < 10 ? '0' : '') + secs;
}

function userPauseEvent() {
  mainControl.textContent = "\u25AE\u25AE";
  loadedTrack.classList.replace("playing", "paused");
  loadedTrack.querySelector('.track-control').textContent = "\u25AE\u25AE";
  player.pause();
}

function userResumeEvent() {
  mainControl.textContent = "\u25B6"
  loadedTrack.classList.replace("paused", "playing");
  loadedTrack.querySelector('.track-control').textContent = "\u25B6";
  player.play()
}

function updateTimelineText() {
  if (!currentTrackData || !player.duration || isNaN(player.duration)) {
    timelinePlayed.style.width = '0%';
    timelinePlayedStatus.textContext = "";
    timelineQueuedStatus.textContent = "(Select a track to play above)";
    return;
  }

  timelinePlayed.style.width = 20 + (timeline.offsetWidth * (player.currentTime / player.duration));
  timelinePlayedStatus.textContent = currentTrackData.title + ' >>> ' + formatTime(player.currentTime);
  timelineQueuedStatus.textContent = '-' + formatTime(player.duration - player.currentTime) + ' <<< ' + currentTrackData.title;
}

function resetPlayer() {
  if (hls) {
    hls.destroy();
    hls = null;
  }
  loadedTrack.classList.remove("playing", "paused");
  loadedTrack.classList.add("idle");
  loadedTrack.querySelector('.track-control').textContent = "\u25B6";
  mainControl.textContent = "\u25A0";
  currentTrackData = null;
  loadedTrack = null;
  updateTimelineText();
}


function loadTrack(src, trackId, trackTitle) {
  currentTrackData = { id: trackId, title: trackTitle, src: src };
  hls = new Hls();
  hls.attachMedia(player);
  hls.on(Hls.Events.MANIFEST_PARSED, function(event, data) {
    if (data.sessionData) {
      var titleData = data.sessionData['com.noise2signal-llc.title'];
      if (titleData && titleData.VALUE) {
        currentTrackData.title = titleData.VALUE;
      }
    }
    player.play();
  });
  hls.on(Hls.Events.ERROR, function(event, data) {
    console.error('HLS error:', data.type, data.details, data.fatal ? '(fatal)' : '');
  });
  hls.loadSource(src);
}

function initializeTrackListeners() {
  var trackItems = document.querySelectorAll('.track-item');
  trackItems.forEach(function(track) {
    var trackControl = track.querySelector('.track-control');
    var trackId = track.getAttribute('data-id');
    var src = track.getAttribute('data-src');
    var title = track.querySelector('.track-name').textContent;

    trackControl.addEventListener('click', function(e) {
      if (loadedTrack != null) {
        if (currentTrackData.id === trackId) {
          if (player.paused) {
            userResumeEvent();
          } else {
            userPauseEvent();
          }
        } else {
          resetPlayer();
        }
      }
      if (loadedTrack === null) {
        loadedTrack = document.querySelector('.track-item[data-id="' + trackId + '"]');
        loadedTrack.classList.replace("idle", "playing");
        mainControl.textContent = "\u25B6"
        loadTrack(src, trackId, title);
      }
    });
  });
}

/* player controls */

mainControl.addEventListener('click', function() {
  if (!loadedTrack) return;
  if (player.paused) {
    userResumeEvent();
  } else {
    userPauseEvent();
  }
});

/* responsive timeline controls */

player.addEventListener('timeupdate', function() {
  if (player.duration && !isNaN(player.duration)) {
    var percent = (player.currentTime / player.duration) * 100;
    timelinePlayed.style.width = percent + '%';
    updateTimelineText();
  }
});

timeline.addEventListener('click', function(e) {
  if (!player.duration || isNaN(player.duration)) return;
  var timelineRect = timeline.getBoundingClientRect();
  var timelineX = e.clientX - timelineRect.left;
  var timelineY = e.clientY - timelineRect.top;
  var dy = timelineRect.height - timelineY;
  var offset =  dy / Math.tan(75 * Math.PI / 180);
  var adjustedX = timelineX + offset;
  var percent = adjustedX / timelineRect.width;
  player.currentTime = percent * player.duration;
});

player.addEventListener('ended', function() {
  resetPlayer();
});

initializeTrackListeners();
