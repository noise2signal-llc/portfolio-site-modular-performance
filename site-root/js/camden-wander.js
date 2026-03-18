var hls = null;
var player = document.getElementById('player');
var playControl = document.getElementById('play-control');
var playControlText = document.getElementById('player-text');
var timeline = document.getElementById('timeline');
var timelinePlayed = document.getElementById('timeline-played');
var timelinePlayedStatus = document.getElementById('played-status');
var timelineQueuedStatus = document.getElementById('queued-status');

var PLAY_ICON = '\u25B6';
var PAUSE_ICON = '\u23F8';

var currentTrackData = null;

function formatTime(seconds) {
  if (isNaN(seconds) || !isFinite(seconds)) return '0:00';
  var mins = Math.floor(seconds / 60);
  var secs = Math.floor(seconds % 60);
  return mins + ':' + (secs < 10 ? '0' : '') + secs;
}

function loadTrack(src, trackId, trackTitle) {
  if (hls) {
    hls.destroy();
  }
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
    playControl.disabled = false;
    player.play();
  });
  hls.on(Hls.Events.ERROR, function(event, data) {
    console.error('HLS error:', data.type, data.details, data.fatal ? '(fatal)' : '');
  });
  hls.loadSource(src);
}

function initializeTrackListeners() {
  var trackItems = document.querySelectorAll('.track-item');
  trackItems.forEach(function(item) {
    var queuer = item.querySelector('.track-queuer');
    var trackId = item.getAttribute('data-id');
    var src = item.getAttribute('data-src');
    var title = item.querySelector('.track-name').textContent;

    queuer.addEventListener('click', function(e) {
      e.preventDefault();
      var wasActive = item.classList.contains('track-active');

      document.querySelectorAll('.track-active').forEach(function(el) {
        el.classList.remove('track-active');
        el.querySelector('.track-queuer').textContent = PLAY_ICON;
      });

      if (wasActive && !player.paused) {
        player.pause();
      } else {
        item.classList.add('track-active');
        queuer.textContent = PAUSE_ICON;
        if (currentTrackData && currentTrackData.id === trackId && player.paused) {
          player.play();
        } else {
          loadTrack(src, trackId, title);
        }
      }
    });
  });

}

/* player controls */

playControl.addEventListener('click', function() {
  if (this.disabled) return;
  if (player.paused) {
    player.play();
  } else {
    player.pause();
  }
});

player.addEventListener('play', function() {
  playControlText.textContent = PAUSE_ICON;
  playControl.classList.add('playing');

  if (currentTrackData) {
    var activeItem = document.querySelector('.track-item[data-id="' + currentTrackData.id + '"]');
    if (activeItem) {
      activeItem.classList.add('track-active');
      activeItem.querySelector('.track-queuer').textContent = PAUSE_ICON;
    }
  }
});

player.addEventListener('pause', function() {
  playControlText.textContent = PLAY_ICON;
  playControl.classList.remove('playing');

  if (currentTrackData) {
    var activeItem = document.querySelector('.track-item[data-id="' + currentTrackData.id + '"]');
    if (activeItem) {
      activeItem.querySelector('.track-queuer').textContent = PLAY_ICON;
    }
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
  if (hls) {
    hls.destroy();
    hls = null;
  }
  document.querySelectorAll('.track-active').forEach(function(el) {
    el.classList.remove('track-active');
    el.querySelector('.track-queuer').textContent = PLAY_ICON;
  });
  playControlText.textContent = PLAY_ICON;
  playControl.classList.remove('playing');
  playControl.disabled = true;
  currentTrackData = null;
  updateTimelineText();
});

initializeTrackListeners();
