
import os
import logging
import time

# first start main logging before including checkhardware_lib
# backup log files
class UnitLogger(object):
    def __init__(self, log_path, file_name=None):
        self.log_levels = {'DEBUG'  : logging.DEBUG,
                           'INFO'   : logging.INFO,
                           'WARNING': logging.WARNING,
                           'ERROR'  : logging.ERROR}
        
        self.log_path = log_path
        self.filename = None
        self.stdout_log_level = 'WARNING'
        self.file_log_level = 'INFO'
        self.backup_depth = 1
        self.file_logger_handler = None
        self.stdout_logger_handler = None
        
        self.logger = logging.getLogger('main')
        self.logger.setLevel(logging.DEBUG)
        self._setup_stdout_logging()
        if file_name is not None:
            self.set_logfile_name(file_name)
        
    def set_logfile_name(self, name):
        self.filename = name
        self._backup_logfiles()
        self._setup_file_logging()
    
    def set_stdout_log_level(self, level):
        _level = level.upper()
        if _level in self.log_levels:
            self.stdout_log_level = _level
            if self.stdout_logger_handler:
                self.stdout_logger_handler.setLevel(self.log_levels[_level])
        else:
            self.logger.error("'{}' is not a valid level".format(level))
    
    def set_file_log_level(self, level):
        _level = level.upper()
        if _level in self.log_levels:
            self.file_log_level = _level
            if self.file_logger_handler:
                self.file_logger_handler.setLevel(self.log_levels[_level])
        else:
            self.logger.error("'{}' is not a valid level".format(level))
        
    def _backup_logfiles(self):
        for nr in range(self.backup_depth-1, -1, -1):
            if nr == 0:
                full_filename = os.path.join(self.log_path, '{}.log'.format(self.filename))
            else:
                full_filename = os.path.join(self.log_path, '{}.log.{}'.format(self.filename, nr))
            full_filename_new = os.path.join(self.log_path, '{}.log.{}'.format(self.filename, nr+1))
            if os.path.exists(full_filename):
                try: 
                    os.rename(full_filename, full_filename_new)
                except WindowsError:
                    os.remove(full_filename_new)
                    os.rename(full_filename, full_filename_new)

    def _setup_stdout_logging(self):
        # create console handler
        stream_handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s %(name)-19s %(levelname)-7s %(message)s')
        stream_handler.setFormatter(formatter)
        stream_handler.setLevel(self.log_levels[self.stdout_log_level])
        self.logger.addHandler(stream_handler)
        self.stdout_logger_handler = self.logger.handlers[0]
        
    def _setup_file_logging(self):
        # create file handler
        full_filename = os.path.join(self.log_path, '{}.log'.format(self.filename))
        file_handler = logging.FileHandler(full_filename, mode='w')
        formatter = logging.Formatter('%(asctime)s %(name)-19s %(levelname)-8s %(message)s')
        file_handler.setFormatter(formatter)
        file_handler.setLevel(self.log_levels[self.file_log_level])
        self.logger.addHandler(file_handler)
        self.file_logger_handler = self.logger.handlers[1]
