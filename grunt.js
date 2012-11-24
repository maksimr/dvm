module.exports = function(grunt) {
    'use strict';

    grunt.initConfig({
        urchin: {
            args: ['-f', 'test']
        },
        // default watch configuration
        watch: {
            bash: {
                files: '*.sh',
                tasks: 'test'
            }
        }
    });

    grunt.registerTask('urchin', 'Urchin is a test framework for shell. It currently supports bash on GNU/Linux and Mac.', function(options) {
        var data = grunt.config('urchin');
        var utils = grunt.utils;
        var verbose = grunt.verbose;
        var args = data.args;
        var log = grunt.log;
        var done = this.async();

        utils.spawn({
            cmd: 'urchin',
            args: args
        }, function(err, result, code) {
            if (!err) {
                result.split('\n').forEach(log.writeln, log);
                return done(null);
            }

            // error handling
            verbose.or.writeln();
            log.write('Running urchin...').error();
            result.split('\n').forEach(log.error, log);
            done(code);
        });
    });

    // Alias the `test` task to run the `mocha` task instead
    grunt.registerTask('test', 'urchin');
    grunt.registerTask('default', 'watch');
};
