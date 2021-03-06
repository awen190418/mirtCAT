context('extra')

test_that('extra', {
    
    mod <- mirt(Science, 1, TOL = NaN, verbose=FALSE) 
    response <- c(0, 1, 2, 3)
    
    expect_error(mirtCAT(mo=mod, local_pattern = response), 
                 "For item 1, responses must be between 1 and 4. Please fix.")
    
    set.seed(1234)
    nitems <- 50
    itemnames <- paste0('Item.', 1:nitems)
    a <- matrix(rlnorm(nitems, .2, .3))
    d <- matrix(rnorm(nitems))
    
    # alternatively, define mo from population values (not run)
    pars <- data.frame(a1=a, d=d)
    mod2 <- generate.mirt_object(pars, itemtype='2PL')
    
    # simple math items
    questions <- answers <- character(nitems)
    choices <- matrix(NA, nitems, 5)
    spacing <- floor(d - min(d)) + 1 #easier items have more variation in the options
    
    for(i in 1:nitems){
        n1 <- sample(1:50, 1)
        n2 <- sample(51:100, 1)
        ans <- n1 + n2
        questions[i] <- paste0(n1, ' + ', n2, ' = ?')
        answers[i] <- as.character(ans)
        ch <- ans + sample(c(-5:-1, 1:5) * spacing[i,], 5)
        ch[sample(1:5, 1)] <- ans
        choices[i, ] <- as.character(ch)
    }
    
    df <- data.frame(Question=questions, Option=choices, 
                                  Type = 'radio', stringsAsFactors = FALSE)
    CATdesign <- mirtCAT(df, mod2, criteria = 'MI', design_elements = TRUE)
    expect_equal(1, findNextItem(CATdesign))
    CATdesign <- updateDesign(CATdesign, new_item = 1, new_response = 1)
    CATdesign <- updateDesign(CATdesign, new_item = 10, new_response = 1)
    expect_equal(3, findNextItem(CATdesign))
    CATdesign <- updateDesign(CATdesign, new_item = 3, new_response = 0)
    expect_equal(20, findNextItem(CATdesign))
    vals <- computeCriteria(CATdesign, criteria = 'MI')
    expect_equal(unname(vals[1:4]), c(0.11804853, 0.43875746, 0.70730264, 0.08116204), tolerance = 1e-4)
    
    # shadow test (less than 20 items, items 31+41 not in same test, item 3 not answered)
    constr_fun <- function(design, person, test){
      # left hand side constrains 
      #    - 1 row per constraint, and ncol must equal number of items
      nitems <- extract.mirt(test@mo, 'nitems')
      lhs <- matrix(0, 3, nitems)
      lhs[1,] <- 1
      lhs[2,c(31,41)] <- 1
      lhs[3,3] <- 1
      
      # relationship direction
      dirs <- c("<=", "<=", '==')
      
      #right hand side
      rhs <- c(20, 1, 0)
    
      #all together
      constraints <- data.frame(lhs, dirs, rhs)
      constraints
    }
    CATdesign <- mirtCAT(df, mod2, design_elements = TRUE,
                         design = list(constr_fun=constr_fun))
    item <- findNextItem(CATdesign, objective=vals)
    expect_equal(item, 20)
    
    customNextItem <- function(person, design, test){
        objective <- computeCriteria(person=person, design=design, test=test, 
                                     criteria = 'MI') 
        item <- findNextItem(person=person, design=design, test=test, 
                             objective=objective)
        item
    }
    set.seed(1)
    res <- mirtCAT(mo = mod2, criteria = 'MI', start_item = 1, 
                   local_pattern = matrix(sample(c(0,1), 50, TRUE), 1), 
                   design = list(customNextItem=customNextItem, constr_fun=constr_fun))
    expect_equal(res$items_answered, c(1,20,41,15,6,24,5,21,29,44,2,39,14,11,32,34,27,23,22,49))
    
    design <- list(min_items = 10, max_items = 45,
                   constraints = list(
                       not_scored = c(1),
                       independent = c(2,5),
                       unordered = c(10:12),
                       ordered = c(15:17),
                       ordered = c(18:20)))
    
    set.seed(1)
    res <- mirtCAT(mo = mod2, criteria = 'MI', design = design, start_item = 1,
                   local_pattern = matrix(rep(0, 50), 1))
    expect_equal(res$items_answered, c(1,18,19,20,24,15,16,17,50,7,25,9,43,10,11,12,44,49,48,35,36,37,46,42,6,29,13,26,34,32,30,38,39,21,45,23,22,28,5,8,4,14,47,40,31))
    
    res <- mirtCAT(mo = mod2, criteria = 'MI', design = design, start_item = c(1, 3),
                   local_pattern = matrix(rep(c(0,1), 50), 2))
    expect_equal(res[[1]]$items_answered[1], 1)
    expect_equal(res[[2]]$items_answered[1], 3)
    
    set.seed(1)
    res <- mirtCAT(mo = mod2, criteria = 'MI', design = design, start_item = 'random',
                   local_pattern = matrix(rep(c(0,1), 50), 2))
    expect_equal(res[[1]]$items_answered[1], 1)
    expect_equal(res[[2]]$items_answered[1], 34)
    
    res <- mirtCAT(mo = mod2, criteria = 'MI', start_item = c('MI', 'random'),
                   local_pattern = matrix(rep(c(0,1), 50), 2))
    expect_equal(res[[1]]$items_answered[1], 20)
    expect_equal(res[[2]]$items_answered[1], 23)
    
})