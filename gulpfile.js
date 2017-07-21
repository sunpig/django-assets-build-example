const cleanCSS = require('gulp-clean-css');
const concat = require('gulp-concat');
const gulp = require('gulp');
const del = require('del');
const sass = require('gulp-sass');
const uglify = require('gulp-uglify');
const pump = require('pump');
const gulpSequence = require('gulp-sequence')
const flatten = require('gulp-flatten');
const include = require("gulp-include");

/*************************************************************************/
/* DEV MODE */
/*************************************************************************/


// Clean the dev build destination
gulp.task('clean:dev', function () {
  return del([
    './build/static/dev/**' // Note that the ** globbing pattern will remove the `dev` directory as well
  ]);
});


// Compile and gather scss files
const sassOptions = {
	outputStyle: 'expanded',
	precision: 6,
	includePaths: [
		'./node_modules/bootstrap/scss'
	]
};
gulp.task('sass', function () {
  return gulp.src('./example_project/**/static/**/*.scss')
    .pipe(sass(sassOptions).on('error', console.log))
    .pipe(flatten({includeParents: -2}))
    .pipe(gulp.dest('./build/static/dev'));
});


// Transform and gather js files
const includeJSOptions = {
	includePaths: [
		'./node_modules'
	]
};
gulp.task('js', function () {
  return gulp.src('./example_project/**/static/**/*.js')
    .pipe(include(includeJSOptions).on('error', console.log))
    .pipe(flatten({includeParents: -2}))
    .pipe(gulp.dest('./build/static/dev'));
});

// Gather static images
gulp.task('img', function () {
  return gulp.src('./example_project/**/static/**/img/**/*.*')
    .pipe(flatten({includeParents: -2}))
	.pipe(gulp.dest('./build/static/dev'));
});


// Prepare all client assets for use in dev mode
// Use gulp-sequence until gulp 4 (which will have native sequential tasks)
// This has to be sequential: the clean task has to happen before we fill the folder!
gulp.task('assets', gulpSequence('clean:dev', ['sass', 'js', 'img']));


// Watch assets and trigger dev mode preparation step.
// CAUTION: using this inside a VM for more than a couple of hours can cause the
// VM to freeze up. I don't know why this happens, or how to fix it.
// As an alternative, you can run the 'assets' task manually when needed.
gulp.task('assetswatch', function(){
	gulp.watch('./example_project/**/static/**/*.*', ['assets']);
});


/*************************************************************************/
/* CREATE OPTIMIZED VERSIONS FOR DEPLOY SCENARIOS */
/*************************************************************************/

// Clean the deployable build destination
gulp.task('clean:optimized', function () {
  return del([
    './build/static/optimized/**' // Note that the ** globbing pattern will remove the `optimized` directory as well
  ]);
});

// Minify JS for use in deploy scenarios
gulp.task('js:optimized', ['js'], function (cb) {
	pump(
		[
			gulp.src('./build/static/dev/**/*.js'),
			uglify(),
			gulp.dest('./build/static/optimized')
		],
		cb
	);
});

// Prepare CSS for use in deploy scenarios
gulp.task('css:optimized', ['sass'], function() {
  return gulp.src('build/static/dev/**/*.css')
    .pipe(cleanCSS())
    .pipe(gulp.dest('build/static/optimized'));
});

// Prepare images for use in deploy scenarios
gulp.task('img:optimized', ['img'], function() {
  return gulp.src('build/static/dev/**/img/**/*')
    .pipe(gulp.dest('build/static/optimized'));
});

// Prepare all client assets for use in deploy scenarios
// Use gulp-sequence until gulp 4 (which will have native sequential tasks)
// This has to be sequential: the clean task has to happen before we fill the folder!
gulp.task('assets:optimized', gulpSequence('clean:optimized', ['css:optimized', 'img:optimized', 'js:optimized']));



/*************************************************************************/
/* DEFAULT */
/*************************************************************************/

// Default task: compile assets for dev mode
gulp.task('default', ['assets']);
