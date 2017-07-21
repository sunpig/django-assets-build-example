var cleanCSS = require('gulp-clean-css');
var concat = require('gulp-concat');
var gulp = require('gulp');
var del = require('del');
var sass = require('gulp-sass');
var uglify = require('gulp-uglify');
var pump = require('pump');
var gulpSequence = require('gulp-sequence')

/*************************************************************************/
/* DEV MODE */
/*************************************************************************/

// Clean the dev build destination
gulp.task('clean:dev', function () {
  return del([
    'build/static/dev/**' // Note that the ** globbing pattern will remove the `dev` directory as well
  ]);
});

var sassOptions = {
	outputStyle: 'expanded',
	precision: 6,
	includePaths: [
		'node_modules/bootstrap/scss'
	]
}

// Compile the scss
gulp.task('sass', function () {
  return gulp.src('example_project/example_project/static/scss/main.scss')
    .pipe(sass(sassOptions).on('error', sass.logError))
    .pipe(concat('main.css'))
    // .pipe(cleanCSS())
    .pipe(gulp.dest('build/static/dev/css'));
});

// Gather and concatenate the main application js
gulp.task('js', function () {
  return gulp.src([
		// Libraries installed from npm
		'node_modules/jquery/dist/jquery.js',
		'node_modules/tether/dist/js/tether.js',
		'node_modules/bootstrap/dist/js/bootstrap.js'
	])
	.pipe(concat('main.js'))
	.pipe(gulp.dest('build/static/dev/js'));
});

// Prepare all client assets for use in dev mode
// Use gulp-sequence until gulp 4 (which will have native sequential tasks)
gulp.task('assets', gulpSequence('clean:dev', ['sass', 'js']));



/*************************************************************************/
/* DEFAULT */
/*************************************************************************/

// Default task: compile assets for dev mode
gulp.task('default', ['assets']);
