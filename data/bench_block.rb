# Benchmark for compare Kernel#proc vs block argument (and vs using yield)

require 'benchmark'

def receiver
  yield
end

def send_using_proc
  receiver &proc if block_given?
end

def send_block_arg(&block)
  receiver &block if block_given?
end

def send_using_yield
  receiver(&proc { yield }) if block_given?
end

Benchmark.bm do |bm|
  bm.report("use proc")  { 1000000.times { send_using_proc  { true } } }
  bm.report("block arg") { 1000000.times { send_block_arg   { true } } }
  bm.report("use yield") { 1000000.times { send_using_yield { true } } }
end

# ******************** result ********************
#
#              user     system      total        real
# use proc   0.670000   0.000000   0.670000 (  0.706581)
# block arg  0.690000   0.010000   0.700000 (  0.712470)
# use yield  1.170000   0.000000   1.170000 (  1.234635)
