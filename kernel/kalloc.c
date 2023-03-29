// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

uint64 MAX_PAGES = 0;
uint64 FREE_PAGES = 0;

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
    struct run *next;
};

struct
{
    struct spinlock lock;
    struct run *freelist;
} kmem;

int reference_count[PHYSTOP / PGSIZE];

void kinit()
{
    initlock(&kmem.lock, "kmem");
    freerange(end, (void *)PHYSTOP);
    MAX_PAGES = FREE_PAGES;
}

void freerange(void *pa_start, void *pa_end)
{
    char *p;
    p = (char *)PGROUNDUP((uint64)pa_start);

    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    {
        // Set the reference  count to 1
        reference_count[(uint64) p / PGSIZE] = 1;
        kfree(p);
    }
}

void increment_refcount(uint64 pa) {
    int page_num = pa / PGSIZE;
    acquire(&kmem.lock);
    if (pa >= PHYSTOP || reference_count[page_num] < 1) {
        panic("increment_refcount");
    }
    reference_count[page_num]++;
    release(&kmem.lock);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    if (MAX_PAGES != 0)
        assert(FREE_PAGES < MAX_PAGES);
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) {
        panic("kfree");
    }

    acquire(&kmem.lock);
    int page_num = (uint64) pa / PGSIZE;
    if (reference_count[page_num] < 1) {
        panic("kfree");
    }

    reference_count[page_num]--;
    int temp = reference_count[page_num];
    release(&kmem.lock);

    if (temp > 0) {
        return;
    }

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);

    r = (struct run *)pa;

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    FREE_PAGES++;
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    assert(FREE_PAGES > 0);
    struct run *r;

    acquire(&kmem.lock);
    r = kmem.freelist;
    if (r) {
        kmem.freelist = r->next;
        int page_num = (uint64) r / PGSIZE;
        // Check that refcount is not 0
        if (reference_count[page_num] != 0) {
            panic("kalloc");
        }
        reference_count[page_num] = 1;
    } 
    release(&kmem.lock);

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    FREE_PAGES--;
    return (void *)r;
}
